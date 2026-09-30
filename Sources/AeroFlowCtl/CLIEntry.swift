// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Darwin

@main
enum AeroFlowCtlMain {
    static func main() async {
        exit(await CLIRuntime.run(arguments: CommandLine.arguments))
    }
}
