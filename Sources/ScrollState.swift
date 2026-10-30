enum ScrollState: String {
    case active, paused, permission, unavailable, systemSetting

    static func resolve(enabled: Bool, trusted: Bool, running: Bool, natural: Bool?) -> Self {
        if !enabled { return .paused }
        if !trusted { return .permission }
        if !running { return .unavailable }
        if natural == false { return .systemSetting }
        return .active
    }

    var title: String {
        switch self {
        case .active: return "运行中"
        case .paused: return "已暂停"
        case .permission: return "待授权"
        case .unavailable: return "待恢复"
        case .systemSetting: return "检查设置"
        }
    }

    var symbol: String {
        switch self {
        case .active: return "arrow.up.arrow.down.circle.fill"
        case .paused: return "pause.circle"
        case .permission: return "lock.circle"
        case .unavailable, .systemSetting: return "exclamationmark.circle"
        }
    }

    var detail: String {
        switch self {
        case .active: return "鼠标滚轮已反转，触控板事件保持原样。"
        case .paused: return "两种设备都按系统设置滚动，随时可以恢复。"
        case .permission: return "允许辅助功能权限后，鼠标独立滚动才会生效。"
        case .unavailable: return "滚动服务暂未就绪，可以尝试重新连接。"
        case .systemSetting: return "请开启系统“自然滚动”，让两种设备按预期工作。"
        }
    }
}
