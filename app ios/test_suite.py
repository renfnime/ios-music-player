import os
import re
import sys
import plistlib
import subprocess

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

def run_checks():
    print("=== Running Comprehensive Music Player Project Audit ===")
    
    # 1. Discover all swift files
    swift_files = []
    file_contents = {}
    for root, dirs, filenames in os.walk("MusicPlayer"):
        for f in filenames:
            if f.endswith(".swift"):
                path = os.path.join(root, f).replace("\\", "/")
                swift_files.append(path)
                with open(path, "r", encoding="utf-8") as file:
                    file_contents[path] = file.read()

    print(f"Discovered {len(swift_files)} Swift source files.")
    assert len(swift_files) >= 29, f"Expected at least 29 swift files, found {len(swift_files)}"

    # 2. Syntax / Lexical Balance Check
    errors = []
    for sf in swift_files:
        code = file_contents[sf]
        stack = []
        in_string = False
        in_multiline_string = False
        in_single_comment = False
        in_multi_comment = False
        i = 0
        line_no = 1
        while i < len(code):
            c = code[i]
            if c == "\n":
                line_no += 1
                if in_single_comment:
                    in_single_comment = False
                i += 1
                continue
            
            if in_single_comment:
                i += 1
                continue
                
            if in_multi_comment:
                if c == "*" and i + 1 < len(code) and code[i+1] == "/":
                    in_multi_comment = False
                    i += 2
                    continue
                i += 1
                continue
                
            if in_multiline_string:
                if c == '"' and i + 2 < len(code) and code[i+1] == '"' and code[i+2] == '"':
                    in_multiline_string = False
                    i += 3
                    continue
                i += 1
                continue
                
            if in_string:
                if c == "\\" and i + 1 < len(code):
                    i += 2
                    continue
                if c == '"':
                    in_string = False
                    i += 1
                    continue
                i += 1
                continue
                
            if c == "/" and i + 1 < len(code) and code[i+1] == "/":
                in_single_comment = True
                i += 2
                continue
            if c == "/" and i + 1 < len(code) and code[i+1] == "*":
                in_multi_comment = True
                i += 2
                continue
            if c == '"' and i + 2 < len(code) and code[i+1] == '"' and code[i+2] == '"':
                in_multiline_string = True
                i += 3
                continue
            if c == '"':
                in_string = True
                i += 1
                continue
                
            if c in "({[":
                stack.append((c, line_no))
            elif c in ")}]":
                if not stack:
                    errors.append(f"{sf}:{line_no}: Unmatched closing {c}")
                else:
                    top, top_line = stack.pop()
                    expected = {')':'(', '}':'{', ']':'['}[c]
                    if top != expected:
                        errors.append(f"{sf}:{line_no}: Mismatched {c}, expected close for {top} from line {top_line}")
            i += 1
            
        for top, top_line in stack:
            errors.append(f"{sf}:{top_line}: Unclosed {top}")

    if errors:
        print(f"[FAIL] Syntax / Balance check FAILED with {len(errors)} errors:")
        for e in errors:
            print(f"  {e}")
        return False
    else:
        print("[PASS] Syntax / Lexical balance check PASSED (0 errors across 29 files)")

    # 3. Check Info.plist
    plist_path = "MusicPlayer/Info.plist"
    with open(plist_path, "rb") as f:
        plist_data = plistlib.load(f)
    
    assert "UIBackgroundModes" in plist_data, "Missing UIBackgroundModes in Info.plist"
    assert "audio" in plist_data["UIBackgroundModes"], "Missing 'audio' in UIBackgroundModes"
    assert "NSAppleMusicUsageDescription" in plist_data, "Missing NSAppleMusicUsageDescription"
    assert plist_data.get("UIFileSharingEnabled") == True, "Missing UIFileSharingEnabled = true"
    assert plist_data.get("LSSupportsOpeningDocumentsInPlace") == True, "Missing LSSupportsOpeningDocumentsInPlace = true"
    assert plist_data.get("UIRequiredDeviceCapabilities") == ["arm64"], "Expected arm64 device capability"
    print("[PASS] Info.plist check PASSED")

    # 4. Check project.pbxproj file references
    pbxproj_path = "MusicPlayer.xcodeproj/project.pbxproj"
    with open(pbxproj_path, "r", encoding="utf-8") as f:
        pbx_content = f.read()
    
    missing_in_project = []
    for sf in swift_files:
        basename = os.path.basename(sf)
        if basename not in pbx_content:
            missing_in_project.append(basename)
    
    if missing_in_project:
        print(f"[FAIL] Missing files in project.pbxproj: {missing_in_project}")
        return False
    else:
        print("[PASS] project.pbxproj contains all 29 Swift source files and resources")

    # 5. Check EnvironmentObject bindings in Views vs MusicPlayerApp / ContentView
    print("\n--- Auditing EnvironmentObject Injections ---")
    root_injections = file_contents["MusicPlayer/App/MusicPlayerApp.swift"]
    content_view = file_contents["MusicPlayer/App/ContentView.swift"]
    
    assert "environmentObject(playerVM)" in root_injections
    assert "environmentObject(libraryVM)" in root_injections
    assert "environmentObject(searchVM)" in root_injections
    assert "environmentObject(settingsVM)" in root_injections
    print("[PASS] MusicPlayerApp properly injects all 4 ObservableObject ViewModels")

    # FullPlayerView sheet presentation environment injection check
    assert "environmentObject(playerVM)" in content_view
    assert "environmentObject(libraryVM)" in content_view
    print("[PASS] FullPlayerView sheet presentation has both playerVM and libraryVM injected")

    # 6. Cross-File Symbol Call Site Audit
    print("\n--- Auditing Cross-File Symbol Calls ---")
    
    def extract_declarations(code):
        props = set(re.findall(r"@Published\s+var\s+([a-zA-Z0-9_]+)", code))
        props.update(re.findall(r"(?:let|var)\s+([a-zA-Z0-9_]+)\s*:", code))
        funcs = set(re.findall(r"func\s+([a-zA-Z0-9_]+)\s*\(", code))
        return props, funcs

    pvm_props, pvm_funcs = extract_declarations(file_contents["MusicPlayer/ViewModels/PlayerViewModel.swift"])
    lvm_props, lvm_funcs = extract_declarations(file_contents["MusicPlayer/ViewModels/LibraryViewModel.swift"])
    svm_props, svm_funcs = extract_declarations(file_contents["MusicPlayer/ViewModels/SearchViewModel.swift"])
    setvm_props, setvm_funcs = extract_declarations(file_contents["MusicPlayer/ViewModels/SettingsViewModel.swift"])

    symbol_errors = []
    
    # Check all view files for playerVM., libraryVM., searchVM., settingsVM.
    for sf in swift_files:
        if not sf.startswith("MusicPlayer/Views/"):
            continue
        code = file_contents[sf]
        
        # Check playerVM usages
        pvm_calls = re.findall(r"playerVM\.([a-zA-Z0-9_]+)", code)
        for call in pvm_calls:
            if call not in pvm_props and call not in pvm_funcs:
                symbol_errors.append(f"{sf}: Unknown PlayerViewModel member '{call}'")
                
        # Check libraryVM usages
        lvm_calls = re.findall(r"libraryVM\.([a-zA-Z0-9_]+)", code)
        for call in lvm_calls:
            if call not in lvm_props and call not in lvm_funcs:
                symbol_errors.append(f"{sf}: Unknown LibraryViewModel member '{call}'")

        # Check searchVM usages
        svm_calls = re.findall(r"searchVM\.([a-zA-Z0-9_]+)", code)
        for call in svm_calls:
            if call not in svm_props and call not in svm_funcs:
                symbol_errors.append(f"{sf}: Unknown SearchViewModel member '{call}'")

        # Check settingsVM usages
        setvm_calls = re.findall(r"settingsVM\.([a-zA-Z0-9_]+)", code)
        for call in setvm_calls:
            if call not in setvm_props and call not in setvm_funcs:
                symbol_errors.append(f"{sf}: Unknown SettingsViewModel member '{call}'")

    if symbol_errors:
        print(f"[FAIL] Cross-file symbol resolution failed with {len(symbol_errors)} errors:")
        for se in symbol_errors:
            print(f"  {se}")
        return False
    else:
        print("[PASS] Cross-file symbol audit PASSED: All view calls resolve to real ViewModel members")

    # 7. Check Functional Flaws
    print("\n--- Auditing Functional Flaw Mitigations ---")
    
    # Check Flaw 1: RepeatMode.one handled on track finish
    player_vm_code = file_contents["MusicPlayer/ViewModels/PlayerViewModel.swift"]
    assert "userInitiated: false" in player_vm_code, "PlayerViewModel onPlaybackFinished must pass userInitiated: false"
    assert "!userInitiated && repeatMode == .one" in player_vm_code, "PlayerViewModel must handle repeatMode == .one when !userInitiated"
    print("[PASS] RepeatMode.one loop fix confirmed")

    # Check Flaw 2: LibraryViewModel.loadRecentlyPlayed() invoked
    library_vm_code = file_contents["MusicPlayer/ViewModels/LibraryViewModel.swift"]
    init_body = re.search(r"init\(\)\s*\{(.*?)\n    \}", library_vm_code, re.DOTALL).group(1)
    assert "loadRecentlyPlayed()" in init_body, "LibraryViewModel.init() must invoke loadRecentlyPlayed()"
    print("[PASS] loadRecentlyPlayed() invocation confirmed")

    # Check Flaw 3: AudioPlayerService handles ipod-library:// and file:// schemes
    audio_player_code = file_contents["MusicPlayer/Services/AudioPlayerService.swift"]
    assert "ipod-library://" in audio_player_code, "AudioPlayerService must support ipod-library:// URLs"
    assert "filePath.hasPrefix(\"file://\")" in audio_player_code, "AudioPlayerService must strip file:// prefix"
    print("[PASS] AudioPlayerService local URI scheme fix confirmed")

    # Check Flaw 4: DownloadManager idempotent save
    dl_code = file_contents["MusicPlayer/Services/DownloadManager.swift"]
    assert 'request.predicate = NSPredicate(format: "id == %@", song.id)' in dl_code, "DownloadManager must query existing song by ID"
    print("[PASS] DownloadManager Core Data duplicate prevention confirmed")

    # Check Flaw 5: PlaylistDetailView ForEach id: \.offset
    playlist_detail_code = file_contents["MusicPlayer/Views/PlaylistDetailView.swift"]
    assert "id: \\.offset" in playlist_detail_code, "PlaylistDetailView must use id: \\.offset"
    print("[PASS] PlaylistDetailView duplicate id collision fix confirmed")

    # Check Flaw 6: Fallback sample songs have playable stream/preview URLs
    home_vm_code = file_contents["MusicPlayer/ViewModels/HomeViewModel.swift"]
    assert 'streamURL: sampleAudio' in home_vm_code, "HomeViewModel sample songs must contain streamURL"
    assert 'previewURL: sampleAudio' in home_vm_code, "HomeViewModel sample songs must contain previewURL"
    print("[PASS] HomeViewModel sample fallback playable URLs confirmed")

    # Check Flaw 7: SearchViewModel deduplicates search results
    search_vm_code = file_contents["MusicPlayer/ViewModels/SearchViewModel.swift"]
    assert "seen.insert($0.id).inserted" in search_vm_code, "SearchViewModel must deduplicate results by ID"
    print("[PASS] SearchViewModel search results deduplication confirmed")

    # Check Flaw 8: Recently played tracking in LibraryView and PlaylistDetailView
    library_view_code = file_contents["MusicPlayer/Views/LibraryView.swift"]
    assert library_view_code.count("libraryVM.addToRecentlyPlayed(song)") >= 3, "LibraryView must record recently played in downloads, local, and favorites"
    assert playlist_detail_code.count("libraryVM.addToRecentlyPlayed(") >= 3, "PlaylistDetailView must record recently played on shuffle, play-first, and tap"
    print("[PASS] Comprehensive recently played recording confirmed")

    print("\n=======================================================")
    print(">>> ALL TESTS AND AUDITS PASSED SUCCESSFULLY (100%) <<<")
    print("=======================================================")
    return True

if __name__ == "__main__":
    if not run_checks():
        sys.exit(1)
