const std = @import("std");
const Path = std.Build.LazyPath;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const t = target.result;

    // Options
    const shared = b.option(bool, "Shared", "Build the Shared Library [default: false]") orelse false;
    const tests = b.option(bool, "Tests", "Build tests [default: false]") orelse false;

    const lib = if (shared) b.addSharedLibrary(.{
        .name = "googletest",
        .target = target,
        .optimize = optimize,
    }) else b.addStaticLibrary(.{
        .name = "googletest",
        .target = target,
        .optimize = optimize,
    });
    lib.defineCMacro("GTEST_OS_WINDOWS", "1");
    lib.addIncludePath(.{ .path = "include"});
    lib.addIncludePath(.{ .path = "src"});
    lib.addCSourceFiles(.{
        .files = &src_files,
        .flags = &cxx_Flags,
    });

    if (lib.rootModuleTarget().abi != .msvc) {
        lib.linkLibCpp();
    } else {
        lib.linkLibC();
    }

    // lib.linkLibC();
    // lib.linkLibCpp();

    lib.installHeadersDirectoryOptions(.{
        .source_dir = .{ .path = "include" },
        .install_dir = .{ .custom = "include" },
        .install_subdir = "",
    });
    lib.installHeadersDirectoryOptions(.{
        .source_dir = .{ .path = "src" },
        .install_dir = .{ .custom = "src" },
        .install_subdir = "",
    });
    lib.installHeadersDirectoryOptions(.{
        .source_dir = .{ .path = "samples" },
        .install_dir = .{ .custom = "samples" },
        .install_subdir = "",
    });

    b.installArtifact(lib);

    if (tests) {
        if (t.os.tag == .windows){

        }

        // buildTest(b, .{
        //     .lib = lib,
        //     .path = "samples/sample1.cc",
        // });
    }
}

fn buildTest(b: *std.Build, info: BuildInfo) void {
    const t = b.standardTargetOptions(.{}).result;

    const test_exe = b.addExecutable(.{
        .name = info.filename(),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    for (info.lib.root_module.include_dirs.items) |include_dir| {
        test_exe.root_module.include_dirs.append(include_dir) catch @panic("Includes append error!");
    }

    if (t.os.tag == .windows) {
        test_exe.subsystem = .Console;
    }

    test_exe.addCSourceFile(info.path, cxx_Flags);
    test_exe.linkLibCpp();
    test_exe.linkLibrary(info.lib);
    b.installArtifact(test_exe);

    const run_cmd = b.addRunArtifact(test_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(
        b.fmt("{s}", .{info.filename()}),
        b.fmt("Run the {s} test", .{info.filename()}),
    );
    run_step.dependOn(&run_cmd.step);
}

const src_files = [_][]const u8{
    "src/gtest_main.cc",
    // "src/gtest-assertion-result.cc",
    // "src/gtest-all.cc",
    // "src/gtest-death-test.cc",
    // "src/gtest-filepath.cc",
    // "src/gtest-matchers.cc",
    // "src/gtest-port.cc",
    // "src/gtest-printers.cc",
    // "src/gtest-test-part.cc",
    // "src/gtest-typed-test.cc",
    // "src/gtest.cc",
};

const cxx_Flags= [_][]const u8{
    "-Wall",
    "-Wextra",
};

const BuildInfo = struct {
    lib: *std.Build.Step.Compile,
    path: []const u8,

    fn filename(self: BuildInfo) []const u8 {
        var split = std.mem.split(u8, std.fs.path.basename(self.path), ".");
        return split.first();
    }
};