#!/usr/bin/env python3
"""Generate a minimal Xcode project for Kook (no xcodegen required)."""

from __future__ import annotations

import os
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP_DIR = ROOT / "App"
PROJECT_DIR = APP_DIR / "Kook.xcodeproj"
SOURCES_ROOT = APP_DIR / "Kook"
TESTS_ROOT = APP_DIR / "KookTests"


def uid() -> str:
    return uuid.uuid4().hex[:24].upper()


def collect_files(directory: Path, suffix: str) -> list[Path]:
    return sorted(p for p in directory.rglob(f"*{suffix}") if p.is_file())


def main() -> None:
    swift_sources = collect_files(SOURCES_ROOT, ".swift")
    json_resources = collect_files(SOURCES_ROOT / "Resources", ".json")
    test_sources = collect_files(TESTS_ROOT, ".swift")

    # Fixed-ish IDs for stability across regenerations of structure keys
    project_id = "A10000000000000000000001"
    main_group = "A10000000000000000000002"
    products_group = "A10000000000000000000003"
    sources_group = "A10000000000000000000004"
    resources_group = "A10000000000000000000005"
    tests_group = "A10000000000000000000006"
    app_target = "A10000000000000000000010"
    test_target = "A10000000000000000000011"
    app_product = "A10000000000000000000012"
    test_product = "A10000000000000000000013"
    sources_phase = "A10000000000000000000020"
    resources_phase = "A10000000000000000000021"
    frameworks_phase = "A10000000000000000000022"
    test_sources_phase = "A10000000000000000000023"
    test_frameworks_phase = "A10000000000000000000024"
    app_config_list = "A10000000000000000000030"
    test_config_list = "A10000000000000000000031"
    project_config_list = "A10000000000000000000032"
    debug_app = "A10000000000000000000040"
    release_app = "A10000000000000000000041"
    debug_test = "A10000000000000000000042"
    release_test = "A10000000000000000000043"
    debug_project = "A10000000000000000000044"
    release_project = "A10000000000000000000045"

    file_refs: dict[Path, str] = {}
    build_files: dict[Path, str] = {}

    for path in swift_sources + json_resources + test_sources:
        file_refs[path] = uid()
        build_files[path] = uid()

    assets_path = SOURCES_ROOT / "Assets.xcassets"
    assets_ref = uid()
    assets_build = uid()

    def rel(path: Path) -> str:
        return path.relative_to(APP_DIR).as_posix()

    # Groups for Domain/Services/Views
    domain_group = uid()
    services_group = uid()
    views_group = uid()

    domain_files = [p for p in swift_sources if "/Domain/" in p.as_posix()]
    services_files = [p for p in swift_sources if "/Services/" in p.as_posix()]
    views_files = [p for p in swift_sources if "/Views/" in p.as_posix()]
    root_swift = [p for p in swift_sources if p.parent == SOURCES_ROOT]

    lines: list[str] = []
    lines.append("// !$*UTF8*$!")
    lines.append("{")
    lines.append("\tarchiveVersion = 1;")
    lines.append("\tclasses = {};")
    lines.append("\tobjectVersion = 56;")
    lines.append("\tobjects = {")
    lines.append("")

    # PBXBuildFile
    lines.append("/* Begin PBXBuildFile section */")
    for path in swift_sources:
        lines.append(f"\t\t{build_files[path]} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {path.name} */; }};")
    for path in json_resources:
        lines.append(f"\t\t{build_files[path]} /* {path.name} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {path.name} */; }};")
    lines.append(f"\t\t{assets_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};")
    for path in test_sources:
        lines.append(f"\t\t{build_files[path]} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {path.name} */; }};")
    lines.append("/* End PBXBuildFile section */")
    lines.append("")

    # PBXFileReference
    lines.append("/* Begin PBXFileReference section */")
    lines.append(f'\t\t{app_product} /* Kook.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Kook.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    lines.append(f'\t\t{test_product} /* KookTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = KookTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')
    for path in swift_sources + test_sources:
        lines.append(f'\t\t{file_refs[path]} /* {path.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {path.name}; sourceTree = "<group>"; }};')
    for path in json_resources:
        lines.append(f'\t\t{file_refs[path]} /* {path.name} */ = {{isa = PBXFileReference; lastKnownFileType = text.json; path = {path.name}; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};')
    lines.append("/* End PBXFileReference section */")
    lines.append("")

    # PBXFrameworksBuildPhase
    lines.append("/* Begin PBXFrameworksBuildPhase section */")
    lines.append(f"\t\t{frameworks_phase} /* Frameworks */ = {{")
    lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append(f"\t\t{test_frameworks_phase} /* Frameworks */ = {{")
    lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXFrameworksBuildPhase section */")
    lines.append("")

    def emit_group(gid: str, name: str, children: list[str], path: str | None = None) -> None:
        lines.append(f"\t\t{gid} /* {name} */ = {{")
        lines.append("\t\t\tisa = PBXGroup;")
        lines.append("\t\t\tchildren = (")
        for c in children:
            lines.append(f"\t\t\t\t{c},")
        lines.append("\t\t\t);")
        if path:
            lines.append(f"\t\t\tpath = {path};")
        else:
            lines.append(f"\t\t\tname = {name};")
        lines.append('\t\t\tsourceTree = "<group>";')
        lines.append("\t\t};")

    # Groups
    lines.append("/* Begin PBXGroup section */")
    emit_group(
        domain_group,
        "Domain",
        [f"{file_refs[p]} /* {p.name} */" for p in domain_files],
        "Domain",
    )
    emit_group(
        services_group,
        "Services",
        [f"{file_refs[p]} /* {p.name} */" for p in services_files],
        "Services",
    )
    emit_group(
        views_group,
        "Views",
        [f"{file_refs[p]} /* {p.name} */" for p in views_files],
        "Views",
    )
    emit_group(
        resources_group,
        "Resources",
        [f"{file_refs[p]} /* {p.name} */" for p in json_resources],
        "Resources",
    )
    emit_group(
        sources_group,
        "Kook",
        (
            [f"{file_refs[p]} /* {p.name} */" for p in root_swift]
            + [
                f"{domain_group} /* Domain */",
                f"{services_group} /* Services */",
                f"{views_group} /* Views */",
                f"{resources_group} /* Resources */",
                f"{assets_ref} /* Assets.xcassets */",
            ]
        ),
        "Kook",
    )
    emit_group(
        tests_group,
        "KookTests",
        [f"{file_refs[p]} /* {p.name} */" for p in test_sources],
        "KookTests",
    )
    emit_group(
        products_group,
        "Products",
        [f"{app_product} /* Kook.app */", f"{test_product} /* KookTests.xctest */"],
    )
    emit_group(
        main_group,
        "Main",
        [
            f"{sources_group} /* Kook */",
            f"{tests_group} /* KookTests */",
            f"{products_group} /* Products */",
        ],
    )
    # fix main group to not use name-only oddly
    lines.append("/* End PBXGroup section */")
    lines.append("")

    # Targets
    lines.append("/* Begin PBXNativeTarget section */")
    lines.append(f"\t\t{app_target} /* Kook */ = {{")
    lines.append("\t\t\tisa = PBXNativeTarget;")
    lines.append("\t\t\tbuildConfigurationList = " + app_config_list + " /* Build configuration list for PBXNativeTarget \"Kook\" */;")
    lines.append("\t\t\tbuildPhases = (")
    lines.append(f"\t\t\t\t{sources_phase} /* Sources */,")
    lines.append(f"\t\t\t\t{frameworks_phase} /* Frameworks */,")
    lines.append(f"\t\t\t\t{resources_phase} /* Resources */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tbuildRules = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdependencies = (")
    lines.append("\t\t\t);")
    lines.append('\t\t\tname = Kook;')
    lines.append('\t\t\tproductName = Kook;')
    lines.append(f"\t\t\tproductReference = {app_product} /* Kook.app */;")
    lines.append('\t\t\tproductType = "com.apple.product-type.application";')
    lines.append("\t\t};")
    lines.append(f"\t\t{test_target} /* KookTests */ = {{")
    lines.append("\t\t\tisa = PBXNativeTarget;")
    lines.append("\t\t\tbuildConfigurationList = " + test_config_list + " /* Build configuration list for PBXNativeTarget \"KookTests\" */;")
    lines.append("\t\t\tbuildPhases = (")
    lines.append(f"\t\t\t\t{test_sources_phase} /* Sources */,")
    lines.append(f"\t\t\t\t{test_frameworks_phase} /* Frameworks */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tbuildRules = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdependencies = (")
    lines.append("\t\t\t);")
    lines.append('\t\t\tname = KookTests;')
    lines.append('\t\t\tproductName = KookTests;')
    lines.append(f"\t\t\tproductReference = {test_product} /* KookTests.xctest */;")
    lines.append('\t\t\tproductType = "com.apple.product-type.bundle.unit-test";')
    lines.append("\t\t};")
    lines.append("/* End PBXNativeTarget section */")
    lines.append("")

    # Project
    lines.append("/* Begin PBXProject section */")
    lines.append(f"\t\t{project_id} /* Project object */ = {{")
    lines.append("\t\t\tisa = PBXProject;")
    lines.append("\t\t\tattributes = {")
    lines.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    lines.append('\t\t\t\tLastSwiftUpdateCheck = 1500;')
    lines.append('\t\t\t\tLastUpgradeCheck = 1500;')
    lines.append("\t\t\t\tTargetAttributes = {")
    lines.append(f"\t\t\t\t\t{app_target} = {{")
    lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    lines.append("\t\t\t\t\t};")
    lines.append(f"\t\t\t\t\t{test_target} = {{")
    lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    lines.append("\t\t\t\t\t\tTestTargetID = " + app_target + ";")
    lines.append("\t\t\t\t\t};")
    lines.append("\t\t\t\t};")
    lines.append("\t\t\t};")
    lines.append(f"\t\t\tbuildConfigurationList = {project_config_list} /* Build configuration list for PBXProject \"Kook\" */;")
    lines.append('\t\t\tcompatibilityVersion = "Xcode 14.0";')
    lines.append("\t\t\tdevelopmentRegion = en;")
    lines.append("\t\t\thasScannedForEncodings = 0;")
    lines.append("\t\t\tknownRegions = (")
    lines.append("\t\t\t\ten,")
    lines.append("\t\t\t\tBase,")
    lines.append("\t\t\t);")
    lines.append(f"\t\t\tmainGroup = {main_group};")
    lines.append(f"\t\t\tproductRefGroup = {products_group} /* Products */;")
    lines.append('\t\t\tprojectDirPath = "";')
    lines.append('\t\t\tprojectRoot = "";')
    lines.append("\t\t\ttargets = (")
    lines.append(f"\t\t\t\t{app_target} /* Kook */,")
    lines.append(f"\t\t\t\t{test_target} /* KookTests */,")
    lines.append("\t\t\t);")
    lines.append("\t\t};")
    lines.append("/* End PBXProject section */")
    lines.append("")

    # Resources
    lines.append("/* Begin PBXResourcesBuildPhase section */")
    lines.append(f"\t\t{resources_phase} /* Resources */ = {{")
    lines.append("\t\t\tisa = PBXResourcesBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    for path in json_resources:
        lines.append(f"\t\t\t\t{build_files[path]} /* {path.name} in Resources */,")
    lines.append(f"\t\t\t\t{assets_build} /* Assets.xcassets in Resources */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXResourcesBuildPhase section */")
    lines.append("")

    # Sources
    lines.append("/* Begin PBXSourcesBuildPhase section */")
    lines.append(f"\t\t{sources_phase} /* Sources */ = {{")
    lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    for path in swift_sources:
        lines.append(f"\t\t\t\t{build_files[path]} /* {path.name} in Sources */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append(f"\t\t{test_sources_phase} /* Sources */ = {{")
    lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    for path in test_sources:
        lines.append(f"\t\t\t\t{build_files[path]} /* {path.name} in Sources */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXSourcesBuildPhase section */")
    lines.append("")

    # Target dependency for tests
    dep_id = uid()
    proxy_id = uid()
    lines.append("/* Begin PBXTargetDependency section */")
    lines.append(f"\t\t{dep_id} /* PBXTargetDependency */ = {{")
    lines.append("\t\t\tisa = PBXTargetDependency;")
    lines.append(f"\t\t\ttarget = {app_target} /* Kook */;")
    lines.append(f"\t\t\ttargetProxy = {proxy_id} /* PBXContainerItemProxy */;")
    lines.append("\t\t};")
    lines.append("/* End PBXTargetDependency section */")
    lines.append("")
    lines.append("/* Begin PBXContainerItemProxy section */")
    lines.append(f"\t\t{proxy_id} /* PBXContainerItemProxy */ = {{")
    lines.append("\t\t\tisa = PBXContainerItemProxy;")
    lines.append(f"\t\t\tcontainerPortal = {project_id} /* Project object */;")
    lines.append("\t\t\tproxyType = 1;")
    lines.append(f'\t\t\tremoteGlobalIDString = {app_target};')
    lines.append('\t\t\tremoteInfo = Kook;')
    lines.append("\t\t};")
    lines.append("/* End PBXContainerItemProxy section */")

    # Patch test target dependencies — rewrite by regenerating that section is hard; inject into objects already closed.
    # Simpler: include dependency id in test target via second pass string replace.

    def xcbuild(cfg_id: str, name: str, settings: dict[str, str]) -> None:
        lines.append(f"\t\t{cfg_id} /* {name} */ = {{")
        lines.append("\t\t\tisa = XCBuildConfiguration;")
        lines.append("\t\t\tbuildSettings = {")
        for k, v in settings.items():
            lines.append(f"\t\t\t\t{k} = {v};")
        lines.append("\t\t\t};")
        lines.append(f"\t\t\tname = {name};")
        lines.append("\t\t};")

    project_common = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "GCC_DYNAMIC_NO_PIC": "NO",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "SDKROOT": "iphoneos",
        "SWIFT_VERSION": "5.0",
    }

    lines.append("/* Begin XCBuildConfiguration section */")
    xcbuild(debug_project, "Debug", {
        **project_common,
        "GCC_PREPROCESSOR_DEFINITIONS": '("DEBUG=1" "$(inherited)")',
        "ONLY_ACTIVE_ARCH": "YES",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"',
    })
    xcbuild(release_project, "Release", {
        **project_common,
        "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"',
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "VALIDATE_PRODUCT": "YES",
    })
    app_settings = {
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "DEVELOPMENT_TEAM": '""',
        "ENABLE_PREVIEWS": "YES",
        "GENERATE_INFOPLIST_FILE": "YES",
        "INFOPLIST_KEY_CFBundleDisplayName": '"Kook"',
        "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
        "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations": '"UIInterfaceOrientationPortrait"',
        "LD_RUNPATH_SEARCH_PATHS": '("$(inherited)" "@executable_path/Frameworks")',
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.susilab.kook",
        "PRODUCT_NAME": '"$(TARGET_NAME)"',
        "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator"',
        "SUPPORTS_MACCATALYST": "NO",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
        "TARGETED_DEVICE_FAMILY": '"1"',
    }
    xcbuild(debug_app, "Debug", app_settings)
    xcbuild(release_app, "Release", app_settings)
    test_settings = {
        "BUNDLE_LOADER": '"$(TEST_HOST)"',
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "GENERATE_INFOPLIST_FILE": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.susilab.kook.tests",
        "PRODUCT_NAME": '"$(TARGET_NAME)"',
        "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator"',
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": '"1"',
        "TEST_HOST": '"$(BUILT_PRODUCTS_DIR)/Kook.app/Kook"',
    }
    xcbuild(debug_test, "Debug", test_settings)
    xcbuild(release_test, "Release", test_settings)
    lines.append("/* End XCBuildConfiguration section */")
    lines.append("")

    def config_list(list_id: str, label: str, debug_id: str, release_id: str) -> None:
        lines.append(f"\t\t{list_id} /* Build configuration list for {label} */ = {{")
        lines.append("\t\t\tisa = XCConfigurationList;")
        lines.append("\t\t\tbuildConfigurations = (")
        lines.append(f"\t\t\t\t{debug_id} /* Debug */,")
        lines.append(f"\t\t\t\t{release_id} /* Release */,")
        lines.append("\t\t\t);")
        lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
        lines.append('\t\t\tdefaultConfigurationName = Release;')
        lines.append("\t\t};")

    lines.append("/* Begin XCConfigurationList section */")
    config_list(project_config_list, 'PBXProject "Kook"', debug_project, release_project)
    config_list(app_config_list, 'PBXNativeTarget "Kook"', debug_app, release_app)
    config_list(test_config_list, 'PBXNativeTarget "KookTests"', debug_test, release_test)
    lines.append("/* End XCConfigurationList section */")
    lines.append("\t};")
    lines.append(f"\trootObject = {project_id} /* Project object */;")
    lines.append("}")

    text = "\n".join(lines) + "\n"
    # Attach test dependency
    text = text.replace(
        f"\t\t\tdependencies = (\n\t\t\t);\n\t\t\tname = KookTests;",
        f"\t\t\tdependencies = (\n\t\t\t\t{dep_id} /* PBXTargetDependency */,\n\t\t\t);\n\t\t\tname = KookTests;",
    )

    PROJECT_DIR.mkdir(parents=True, exist_ok=True)
    (PROJECT_DIR / "project.pbxproj").write_text(text, encoding="utf-8")

    scheme_dir = PROJECT_DIR / "xcshareddata" / "xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
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
               BlueprintIdentifier = "{app_target}"
               BuildableName = "Kook.app"
               BlueprintName = "Kook"
               ReferencedContainer = "container:Kook.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{test_target}"
               BuildableName = "KookTests.xctest"
               BlueprintName = "KookTests"
               ReferencedContainer = "container:Kook.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
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
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target}"
            BuildableName = "Kook.app"
            BlueprintName = "Kook"
            ReferencedContainer = "container:Kook.xcodeproj">
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
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target}"
            BuildableName = "Kook.app"
            BlueprintName = "Kook"
            ReferencedContainer = "container:Kook.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug" />
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES" />
</Scheme>
"""
    (scheme_dir / "Kook.xcscheme").write_text(scheme, encoding="utf-8")
    print(f"Wrote {PROJECT_DIR}")
    print(f"  {len(swift_sources)} app sources, {len(json_resources)} json, {len(test_sources)} tests")


if __name__ == "__main__":
    main()
