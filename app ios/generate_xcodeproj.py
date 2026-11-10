#!/usr/bin/env python3
"""
Generate an Xcode project file (MusicPlayer.xcodeproj/project.pbxproj)
for the MusicPlayer iOS app.
"""

import os
import hashlib
import uuid

def make_id(name):
    """Generate a deterministic 24-char hex ID from a name."""
    h = hashlib.md5(name.encode()).hexdigest()[:24].upper()
    return h

# Project root
PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
MUSIC_PLAYER_DIR = os.path.join(PROJECT_DIR, "MusicPlayer")

# Define all source files relative to MusicPlayer/
SOURCE_FILES = [
    ("App/AppTheme.swift", "App"),
    ("App/ContentView.swift", "App"),
    ("App/MusicPlayerApp.swift", "App"),
    ("Models/Models.swift", "Models"),
    ("Models/PersistenceController.swift", "Models"),
    ("Services/AudioPlayerService.swift", "Services"),
    ("Services/DeezerService.swift", "Services"),
    ("Services/DownloadManager.swift", "Services"),
    ("Services/JamendoService.swift", "Services"),
    ("Services/LastFMService.swift", "Services"),
    ("Services/LocalMusicService.swift", "Services"),
    ("Services/LyricsService.swift", "Services"),
    ("Services/NetworkService.swift", "Services"),
    ("Services/SoundCloudService.swift", "Services"),
    ("Services/YouTubeService.swift", "Services"),
    ("ViewModels/HomeViewModel.swift", "ViewModels"),
    ("ViewModels/LibraryViewModel.swift", "ViewModels"),
    ("ViewModels/PlayerViewModel.swift", "ViewModels"),
    ("ViewModels/SearchViewModel.swift", "ViewModels"),
    ("ViewModels/SettingsViewModel.swift", "ViewModels"),
    ("Views/EqualizerView.swift", "Views"),
    ("Views/FullPlayerView.swift", "Views"),
    ("Views/HomeView.swift", "Views"),
    ("Views/LibraryView.swift", "Views"),
    ("Views/MiniPlayerView.swift", "Views"),
    ("Views/PlaylistDetailView.swift", "Views"),
    ("Views/QueueView.swift", "Views"),
    ("Views/SearchView.swift", "Views"),
    ("Views/SettingsView.swift", "Views"),
    ("Views/YouTubePlayerView.swift", "Views"),
]

RESOURCE_FILES = [
    ("Assets.xcassets", None),
    ("Info.plist", None),
]

# Generate IDs
ROOT_OBJ_ID = make_id("root_object")
MAIN_GROUP_ID = make_id("main_group")
PROJECT_ID = make_id("project")
PRODUCTS_GROUP_ID = make_id("products_group")
APP_TARGET_ID = make_id("app_target")
APP_PRODUCT_ID = make_id("app_product")
SOURCES_BUILD_PHASE_ID = make_id("sources_build_phase")
RESOURCES_BUILD_PHASE_ID = make_id("resources_build_phase")
FRAMEWORKS_BUILD_PHASE_ID = make_id("frameworks_build_phase")
DEBUG_CONFIG_ID = make_id("debug_config")
RELEASE_CONFIG_ID = make_id("release_config")
TARGET_DEBUG_CONFIG_ID = make_id("target_debug_config")
TARGET_RELEASE_CONFIG_ID = make_id("target_release_config")
PROJECT_CONFIG_LIST_ID = make_id("project_config_list")
TARGET_CONFIG_LIST_ID = make_id("target_config_list")
MUSICPLAYER_GROUP_ID = make_id("musicplayer_group")

# Group IDs for subfolders
GROUP_IDS = {}
for grp in ["App", "Models", "Services", "ViewModels", "Views"]:
    GROUP_IDS[grp] = make_id(f"group_{grp}")

# Generate file reference IDs and build file IDs
file_refs = {}
build_files = {}

for path, group in SOURCE_FILES:
    fname = os.path.basename(path)
    file_refs[path] = make_id(f"fileref_{path}")
    build_files[path] = make_id(f"buildfile_{path}")

resource_refs = {}
resource_build_files = {}
for path, _ in RESOURCE_FILES:
    resource_refs[path] = make_id(f"fileref_{path}")
    if path != "Info.plist":  # Info.plist is not a build resource
        resource_build_files[path] = make_id(f"buildfile_{path}")

# Build the pbxproj content
lines = []
lines.append("// !$*UTF8*$!")
lines.append("{")
lines.append("\tarchiveVersion = 1;")
lines.append("\tclasses = {")
lines.append("\t};")
lines.append("\tobjectVersion = 56;")
lines.append("\tobjects = {")
lines.append("")

# PBXBuildFile section
lines.append("/* Begin PBXBuildFile section */")
for path, group in SOURCE_FILES:
    fname = os.path.basename(path)
    lines.append(f"\t\t{build_files[path]} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {fname} */; }};")
for path, _ in RESOURCE_FILES:
    if path in resource_build_files:
        fname = os.path.basename(path)
        lines.append(f"\t\t{resource_build_files[path]} /* {fname} in Resources */ = {{isa = PBXBuildFile; fileRef = {resource_refs[path]} /* {fname} */; }};")
lines.append("/* End PBXBuildFile section */")
lines.append("")

# PBXFileReference section
lines.append("/* Begin PBXFileReference section */")
for path, group in SOURCE_FILES:
    fname = os.path.basename(path)
    lines.append(f"\t\t{file_refs[path]} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fname}; sourceTree = \"<group>\"; }};")
for path, _ in RESOURCE_FILES:
    fname = os.path.basename(path)
    if path == "Assets.xcassets":
        lines.append(f"\t\t{resource_refs[path]} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {fname}; sourceTree = \"<group>\"; }};")
    elif path == "Info.plist":
        lines.append(f"\t\t{resource_refs[path]} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = {fname}; sourceTree = \"<group>\"; }};")
lines.append(f"\t\t{APP_PRODUCT_ID} /* MusicPlayer.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MusicPlayer.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
lines.append("/* End PBXFileReference section */")
lines.append("")

# PBXFrameworksBuildPhase section
lines.append("/* Begin PBXFrameworksBuildPhase section */")
lines.append(f"\t\t{FRAMEWORKS_BUILD_PHASE_ID} /* Frameworks */ = {{")
lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")
lines.append("/* End PBXFrameworksBuildPhase section */")
lines.append("")

# PBXGroup section
lines.append("/* Begin PBXGroup section */")

# Main group
lines.append(f"\t\t{MAIN_GROUP_ID} = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{MUSICPLAYER_GROUP_ID} /* MusicPlayer */,")
lines.append(f"\t\t\t\t{PRODUCTS_GROUP_ID} /* Products */,")
lines.append("\t\t\t);")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

# Products group
lines.append(f"\t\t{PRODUCTS_GROUP_ID} /* Products */ = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{APP_PRODUCT_ID} /* MusicPlayer.app */,")
lines.append("\t\t\t);")
lines.append("\t\t\tname = Products;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

# MusicPlayer group
lines.append(f"\t\t{MUSICPLAYER_GROUP_ID} /* MusicPlayer */ = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
for grp in ["App", "Models", "Services", "ViewModels", "Views"]:
    lines.append(f"\t\t\t\t{GROUP_IDS[grp]} /* {grp} */,")
for path, _ in RESOURCE_FILES:
    fname = os.path.basename(path)
    lines.append(f"\t\t\t\t{resource_refs[path]} /* {fname} */,")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = MusicPlayer;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

# Subgroup for each folder
for grp in ["App", "Models", "Services", "ViewModels", "Views"]:
    grp_files = [(p, g) for p, g in SOURCE_FILES if g == grp]
    lines.append(f"\t\t{GROUP_IDS[grp]} /* {grp} */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    for path, _ in grp_files:
        fname = os.path.basename(path)
        lines.append(f"\t\t\t\t{file_refs[path]} /* {fname} */,")
    lines.append("\t\t\t);")
    lines.append(f"\t\t\tpath = {grp};")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

lines.append("/* End PBXGroup section */")
lines.append("")

# PBXNativeTarget section
lines.append("/* Begin PBXNativeTarget section */")
lines.append(f"\t\t{APP_TARGET_ID} /* MusicPlayer */ = {{")
lines.append("\t\t\tisa = PBXNativeTarget;")
lines.append(f"\t\t\tbuildConfigurationList = {TARGET_CONFIG_LIST_ID} /* Build configuration list for PBXNativeTarget \"MusicPlayer\" */;")
lines.append("\t\t\tbuildPhases = (")
lines.append(f"\t\t\t\t{SOURCES_BUILD_PHASE_ID} /* Sources */,")
lines.append(f"\t\t\t\t{FRAMEWORKS_BUILD_PHASE_ID} /* Frameworks */,")
lines.append(f"\t\t\t\t{RESOURCES_BUILD_PHASE_ID} /* Resources */,")
lines.append("\t\t\t);")
lines.append("\t\t\tbuildRules = (")
lines.append("\t\t\t);")
lines.append("\t\t\tdependencies = (")
lines.append("\t\t\t);")
lines.append("\t\t\tname = MusicPlayer;")
lines.append(f"\t\t\tproductName = MusicPlayer;")
lines.append(f"\t\t\tproductReference = {APP_PRODUCT_ID} /* MusicPlayer.app */;")
lines.append("\t\t\tproductType = \"com.apple.product-type.application\";")
lines.append("\t\t};")
lines.append("/* End PBXNativeTarget section */")
lines.append("")

# PBXProject section
lines.append("/* Begin PBXProject section */")
lines.append(f"\t\t{PROJECT_ID} /* Project object */ = {{")
lines.append("\t\t\tisa = PBXProject;")
lines.append("\t\t\tattributes = {")
lines.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
lines.append(f"\t\t\t\tLastSwiftUpdateCheck = 1500;")
lines.append(f"\t\t\t\tLastUpgradeCheck = 1500;")
lines.append("\t\t\t\tTargetAttributes = {")
lines.append(f"\t\t\t\t\t{APP_TARGET_ID} = {{")
lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
lines.append("\t\t\t\t\t};")
lines.append("\t\t\t\t};")
lines.append("\t\t\t};")
lines.append(f"\t\t\tbuildConfigurationList = {PROJECT_CONFIG_LIST_ID} /* Build configuration list for PBXProject \"MusicPlayer\" */;")
lines.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
lines.append("\t\t\tdevelopmentRegion = en;")
lines.append("\t\t\thasScannedForEncodings = 0;")
lines.append("\t\t\tknownRegions = (")
lines.append("\t\t\t\ten,")
lines.append("\t\t\t\tBase,")
lines.append("\t\t\t);")
lines.append(f"\t\t\tmainGroup = {MAIN_GROUP_ID};")
lines.append(f"\t\t\tproductRefGroup = {PRODUCTS_GROUP_ID} /* Products */;")
lines.append("\t\t\tprojectDirPath = \"\";")
lines.append("\t\t\tprojectRoot = \"\";")
lines.append("\t\t\ttargets = (")
lines.append(f"\t\t\t\t{APP_TARGET_ID} /* MusicPlayer */,")
lines.append("\t\t\t);")
lines.append("\t\t};")
lines.append("/* End PBXProject section */")
lines.append("")

# PBXResourcesBuildPhase section
lines.append("/* Begin PBXResourcesBuildPhase section */")
lines.append(f"\t\t{RESOURCES_BUILD_PHASE_ID} /* Resources */ = {{")
lines.append("\t\t\tisa = PBXResourcesBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
for path, _ in RESOURCE_FILES:
    if path in resource_build_files:
        fname = os.path.basename(path)
        lines.append(f"\t\t\t\t{resource_build_files[path]} /* {fname} in Resources */,")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")
lines.append("/* End PBXResourcesBuildPhase section */")
lines.append("")

# PBXSourcesBuildPhase section
lines.append("/* Begin PBXSourcesBuildPhase section */")
lines.append(f"\t\t{SOURCES_BUILD_PHASE_ID} /* Sources */ = {{")
lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
for path, group in SOURCE_FILES:
    fname = os.path.basename(path)
    lines.append(f"\t\t\t\t{build_files[path]} /* {fname} in Sources */,")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")
lines.append("/* End PBXSourcesBuildPhase section */")
lines.append("")

# XCBuildConfiguration section
lines.append("/* Begin XCBuildConfiguration section */")

# Project Debug
lines.append(f"\t\t{DEBUG_CONFIG_ID} /* Debug */ = {{")
lines.append("\t\t\tisa = XCBuildConfiguration;")
lines.append("\t\t\tbuildSettings = {")
lines.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
lines.append("\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;")
lines.append("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
lines.append("\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;")
lines.append("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";")
lines.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
lines.append("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
lines.append("\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;")
lines.append("\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;")
lines.append("\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_COMMA = YES;")
lines.append("\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;")
lines.append("\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;")
lines.append("\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;")
lines.append("\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;")
lines.append("\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;")
lines.append("\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;")
lines.append("\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;")
lines.append("\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;")
lines.append("\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;")
lines.append("\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;")
lines.append("\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;")
lines.append("\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;")
lines.append("\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;")
lines.append("\t\t\t\tCOPY_PHASE_STRIP = NO;")
lines.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
lines.append("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
lines.append("\t\t\t\tENABLE_TESTABILITY = YES;")
lines.append("\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;")
lines.append("\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;")
lines.append("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
lines.append("\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;")
lines.append("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
lines.append("\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (")
lines.append("\t\t\t\t\t\"DEBUG=1\",")
lines.append("\t\t\t\t\t\"$(inherited)\",")
lines.append("\t\t\t\t);")
lines.append("\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;")
lines.append("\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;")
lines.append("\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;")
lines.append("\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;")
lines.append("\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;")
lines.append("\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;")
lines.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
lines.append("\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;")
lines.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;")
lines.append("\t\t\t\tMTL_FAST_MATH = YES;")
lines.append("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
lines.append("\t\t\t\tSDKROOT = iphoneos;")
lines.append("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = \"DEBUG $(inherited)\";")
lines.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
lines.append("\t\t\t};")
lines.append("\t\t\tname = Debug;")
lines.append("\t\t};")

# Project Release
lines.append(f"\t\t{RELEASE_CONFIG_ID} /* Release */ = {{")
lines.append("\t\t\tisa = XCBuildConfiguration;")
lines.append("\t\t\tbuildSettings = {")
lines.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
lines.append("\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;")
lines.append("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
lines.append("\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;")
lines.append("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";")
lines.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
lines.append("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
lines.append("\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;")
lines.append("\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;")
lines.append("\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_COMMA = YES;")
lines.append("\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;")
lines.append("\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;")
lines.append("\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;")
lines.append("\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;")
lines.append("\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;")
lines.append("\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;")
lines.append("\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;")
lines.append("\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;")
lines.append("\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;")
lines.append("\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;")
lines.append("\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;")
lines.append("\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;")
lines.append("\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;")
lines.append("\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;")
lines.append("\t\t\t\tCOPY_PHASE_STRIP = NO;")
lines.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";")
lines.append("\t\t\t\tENABLE_NS_ASSERTIONS = NO;")
lines.append("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
lines.append("\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;")
lines.append("\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;")
lines.append("\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;")
lines.append("\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;")
lines.append("\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;")
lines.append("\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;")
lines.append("\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;")
lines.append("\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;")
lines.append("\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;")
lines.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
lines.append("\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;")
lines.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;")
lines.append("\t\t\t\tMTL_FAST_MATH = YES;")
lines.append("\t\t\t\tSDKROOT = iphoneos;")
lines.append("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
lines.append("\t\t\t\tVALIDATE_PRODUCT = YES;")
lines.append("\t\t\t};")
lines.append("\t\t\tname = Release;")
lines.append("\t\t};")

# Target Debug
lines.append(f"\t\t{TARGET_DEBUG_CONFIG_ID} /* Debug */ = {{")
lines.append("\t\t\tisa = XCBuildConfiguration;")
lines.append("\t\t\tbuildSettings = {")
lines.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
lines.append("\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;")
lines.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
lines.append("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
lines.append("\t\t\t\tENABLE_PREVIEWS = YES;")
lines.append("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
lines.append("\t\t\t\tINFOPLIST_FILE = MusicPlayer/Info.plist;")
lines.append("\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;")
lines.append("\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;")
lines.append("\t\t\t\tINFOPLIST_KEY_UIStatusBarStyle = \"\";")
lines.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
lines.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
lines.append("\t\t\t\t\t\"$(inherited)\",")
lines.append("\t\t\t\t\t\"@executable_path/Frameworks\",")
lines.append("\t\t\t\t);")
lines.append("\t\t\t\tMARKETING_VERSION = 1.0;")
lines.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.musicplayer.app;")
lines.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
lines.append("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
lines.append("\t\t\t\tSWIFT_VERSION = 5.0;")
lines.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
lines.append("\t\t\t};")
lines.append("\t\t\tname = Debug;")
lines.append("\t\t};")

# Target Release
lines.append(f"\t\t{TARGET_RELEASE_CONFIG_ID} /* Release */ = {{")
lines.append("\t\t\tisa = XCBuildConfiguration;")
lines.append("\t\t\tbuildSettings = {")
lines.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
lines.append("\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;")
lines.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
lines.append("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
lines.append("\t\t\t\tENABLE_PREVIEWS = YES;")
lines.append("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
lines.append("\t\t\t\tINFOPLIST_FILE = MusicPlayer/Info.plist;")
lines.append("\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;")
lines.append("\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;")
lines.append("\t\t\t\tINFOPLIST_KEY_UIStatusBarStyle = \"\";")
lines.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
lines.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
lines.append("\t\t\t\t\t\"$(inherited)\",")
lines.append("\t\t\t\t\t\"@executable_path/Frameworks\",")
lines.append("\t\t\t\t);")
lines.append("\t\t\t\tMARKETING_VERSION = 1.0;")
lines.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.musicplayer.app;")
lines.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
lines.append("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
lines.append("\t\t\t\tSWIFT_VERSION = 5.0;")
lines.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
lines.append("\t\t\t};")
lines.append("\t\t\tname = Release;")
lines.append("\t\t};")

lines.append("/* End XCBuildConfiguration section */")
lines.append("")

# XCConfigurationList section
lines.append("/* Begin XCConfigurationList section */")

# Project config list
lines.append(f"\t\t{PROJECT_CONFIG_LIST_ID} /* Build configuration list for PBXProject \"MusicPlayer\" */ = {{")
lines.append("\t\t\tisa = XCConfigurationList;")
lines.append("\t\t\tbuildConfigurations = (")
lines.append(f"\t\t\t\t{DEBUG_CONFIG_ID} /* Debug */,")
lines.append(f"\t\t\t\t{RELEASE_CONFIG_ID} /* Release */,")
lines.append("\t\t\t);")
lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
lines.append("\t\t\tdefaultConfigurationName = Release;")
lines.append("\t\t};")

# Target config list
lines.append(f"\t\t{TARGET_CONFIG_LIST_ID} /* Build configuration list for PBXNativeTarget \"MusicPlayer\" */ = {{")
lines.append("\t\t\tisa = XCConfigurationList;")
lines.append("\t\t\tbuildConfigurations = (")
lines.append(f"\t\t\t\t{TARGET_DEBUG_CONFIG_ID} /* Debug */,")
lines.append(f"\t\t\t\t{TARGET_RELEASE_CONFIG_ID} /* Release */,")
lines.append("\t\t\t);")
lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
lines.append("\t\t\tdefaultConfigurationName = Release;")
lines.append("\t\t};")

lines.append("/* End XCConfigurationList section */")
lines.append("")

# Close objects and root
lines.append("\t};")
lines.append(f"\trootObject = {PROJECT_ID} /* Project object */;")
lines.append("}")
lines.append("")

content = "\n".join(lines)

# Create xcodeproj directory
xcodeproj_dir = os.path.join(PROJECT_DIR, "MusicPlayer.xcodeproj")
os.makedirs(xcodeproj_dir, exist_ok=True)

# Write pbxproj
pbxproj_path = os.path.join(xcodeproj_dir, "project.pbxproj")
with open(pbxproj_path, "w", encoding="utf-8") as f:
    f.write(content)

print(f"Generated: {pbxproj_path}")

# Create xcshareddata/xcschemes directory and scheme
schemes_dir = os.path.join(xcodeproj_dir, "xcshareddata", "xcschemes")
os.makedirs(schemes_dir, exist_ok=True)

scheme_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{APP_TARGET_ID}"
               BuildableName = "MusicPlayer.app"
               BlueprintName = "MusicPlayer"
               ReferencedContainer = "container:MusicPlayer.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         reuseLastBuildArtifact = "YES">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{APP_TARGET_ID}"
            BuildableName = "MusicPlayer.app"
            BlueprintName = "MusicPlayer"
            ReferencedContainer = "container:MusicPlayer.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         reuseLastBuildArtifact = "YES">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{APP_TARGET_ID}"
            BuildableName = "MusicPlayer.app"
            BlueprintName = "MusicPlayer"
            ReferencedContainer = "container:MusicPlayer.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

scheme_path = os.path.join(schemes_dir, "MusicPlayer.xcscheme")
with open(scheme_path, "w", encoding="utf-8") as f:
    f.write(scheme_content)

print(f"Generated: {scheme_path}")

# Create workspace settings
workspace_dir = os.path.join(xcodeproj_dir, "project.xcworkspace")
os.makedirs(workspace_dir, exist_ok=True)

workspace_contents = """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
"""

workspace_path = os.path.join(workspace_dir, "contents.xcworkspacedata")
with open(workspace_path, "w", encoding="utf-8") as f:
    f.write(workspace_contents)

print(f"Generated: {workspace_path}")

# Shared workspace settings
shared_data_dir = os.path.join(workspace_dir, "xcshareddata")
os.makedirs(shared_data_dir, exist_ok=True)

workspace_settings = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>IDEWorkspaceSharedSettings_AutocreateContextsIfNeeded</key>
	<false/>
</dict>
</plist>
"""

ws_settings_path = os.path.join(shared_data_dir, "WorkspaceSettings.xcsettings")
with open(ws_settings_path, "w", encoding="utf-8") as f:
    f.write(workspace_settings)

print(f"Generated: {ws_settings_path}")
print("\nXcode project generation complete!")
