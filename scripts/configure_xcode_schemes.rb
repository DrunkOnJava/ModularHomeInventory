#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'
SCHEME_NAME = 'HomeInventoryModular'

puts "📋 Configuring Xcode schemes..."

# Open the project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find targets
app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

unless app_target && test_target
  puts "❌ Required targets not found!"
  exit 1
end

# Ensure scheme directory exists
scheme_dir = File.join(PROJECT_PATH, 'xcshareddata', 'xcschemes')
FileUtils.mkdir_p(scheme_dir)

# Create the main scheme
scheme_path = File.join(scheme_dir, "#{SCHEME_NAME}.xcscheme")
scheme_content = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1540"
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
               BlueprintIdentifier = "#{app_target.uuid}"
               BuildableName = "HomeInventoryModular.app"
               BlueprintName = "HomeInventoryModular"
               ReferencedContainer = "container:HomeInventoryModular.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "#{test_target.uuid}"
               BuildableName = "HomeInventoryModularTests.xctest"
               BlueprintName = "HomeInventoryModularTests"
               ReferencedContainer = "container:HomeInventoryModular.xcodeproj">
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
            skipped = "NO"
            parallelizable = "NO"
            testExecutionOrdering = "random">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "#{test_target.uuid}"
               BuildableName = "HomeInventoryModularTests.xctest"
               BlueprintName = "HomeInventoryModularTests"
               ReferencedContainer = "container:HomeInventoryModular.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
      <EnvironmentVariables>
         <EnvironmentVariable
            key = "RECORD_SNAPSHOTS"
            value = "YES"
            isEnabled = "YES">
         </EnvironmentVariable>
      </EnvironmentVariables>
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
            BlueprintIdentifier = "#{app_target.uuid}"
            BuildableName = "HomeInventoryModular.app"
            BlueprintName = "HomeInventoryModular"
            ReferencedContainer = "container:HomeInventoryModular.xcodeproj">
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
            BlueprintIdentifier = "#{app_target.uuid}"
            BuildableName = "HomeInventoryModular.app"
            BlueprintName = "HomeInventoryModular"
            ReferencedContainer = "container:HomeInventoryModular.xcodeproj">
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
XML

File.write(scheme_path, scheme_content)
puts "✅ Created main scheme: #{scheme_path}"

# Create a test-only scheme
test_scheme_path = File.join(scheme_dir, "HomeInventoryModularTests.xcscheme")
test_scheme_content = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1540"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "#{app_target.uuid}"
               BuildableName = "HomeInventoryModular.app"
               BlueprintName = "HomeInventoryModular"
               ReferencedContainer = "container:HomeInventoryModular.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "#{test_target.uuid}"
               BuildableName = "HomeInventoryModularTests.xctest"
               BlueprintName = "HomeInventoryModularTests"
               ReferencedContainer = "container:HomeInventoryModular.xcodeproj">
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
            skipped = "NO"
            parallelizable = "NO"
            testExecutionOrdering = "random">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "#{test_target.uuid}"
               BuildableName = "HomeInventoryModularTests.xctest"
               BlueprintName = "HomeInventoryModularTests"
               ReferencedContainer = "container:HomeInventoryModular.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
      <EnvironmentVariables>
         <EnvironmentVariable
            key = "RECORD_SNAPSHOTS"
            value = "YES"
            isEnabled = "YES">
         </EnvironmentVariable>
      </EnvironmentVariables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = ""
      selectedLauncherIdentifier = "Xcode.IDEFoundation.Launcher.PosixSpawn"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
XML

File.write(test_scheme_path, test_scheme_content)
puts "✅ Created test scheme: #{test_scheme_path}"

puts ""
puts "📋 Summary:"
puts "   - Main scheme: #{SCHEME_NAME}"
puts "   - Test scheme: HomeInventoryModularTests"
puts "   - Environment: RECORD_SNAPSHOTS=YES"
puts ""
puts "🚀 Schemes configured successfully!"