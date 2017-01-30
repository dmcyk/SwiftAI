import PackageDescription

let package = Package(
    name: "Task2",
    dependencies: [
        .Package(url: "https://github.com/dmcyk/cvut_utils", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/dmcyk/cvut_console", majorVersion: 0, minor: 3)

    ]
)
