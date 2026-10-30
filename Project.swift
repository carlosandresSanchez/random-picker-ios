import ProjectDescription

let signing: SettingsDictionary = [
    "DEVELOPMENT_TEAM": "9DQML7UR7T",
    "CODE_SIGN_STYLE": "Automatic",
    "SWIFT_VERSION": "5.0",
]

let project = Project(
    name: "RandomPicker",
    targets: [
        .target(
            name: "RandomPicker",
            destinations: .iOS,
            product: .app,
            bundleId: "com.carlossanchez.RandomPicker",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Random Picker",
                "UILaunchScreen": [:],
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
            ]),
            sources: ["Sources/**"],
            settings: .settings(base: signing)
        ),
        .target(
            name: "RandomPickerTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.carlossanchez.RandomPickerTests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "RandomPicker")],
            settings: .settings(base: signing)
        ),
    ]
)
