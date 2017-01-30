import PackageDescription

let package = Package(
    name: "Task3",
    dependencies: [
        .Package(url: "https://github.com/dmcyk/cvut_utils", majorVersion: 0, minor: 4),
        .Package(url: "https://github.com/dmcyk/cvut_console", majorVersion: 0, minor: 9)

    ]
)
