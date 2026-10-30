import SwiftUI

private enum Palette {
    static let ink = Color(red: 0.13, green: 0.15, blue: 0.23)
    static let muted = Color(red: 0.48, green: 0.50, blue: 0.58)
    static let accent = Color(red: 0.36, green: 0.33, blue: 0.87)
    static let green = Color(red: 0.14, green: 0.52, blue: 0.41)
    static let amber = Color(red: 0.66, green: 0.39, blue: 0.12)
    static let line = Color(red: 0.89, green: 0.90, blue: 0.93)
    static let canvas = Color(red: 0.975, green: 0.975, blue: 0.986)
}

enum Page: String, CaseIterable {
    case control = "滚动控制", preferences = "偏好设置", guide = "使用指南"
    var icon: String {
        switch self {
        case .control: return "slider.horizontal.3"
        case .preferences: return "gearshape"
        case .guide: return "book.closed"
        }
    }
}

struct MainView: View {
    @ObservedObject var model: AppModel
    @State private var page: Page = .control

    init(model: AppModel, initialPage: Page = .control) {
        self.model = model
        _page = State(initialValue: initialPage)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Rectangle().fill(Palette.line).frame(width: 1)
            VStack(alignment: .leading, spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch page {
                        case .control: control
                        case .preferences: preferences
                        case .guide: guide
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 22)
                    .padding(.bottom, 18)
                }
                .id(page)
                .scrollIndicators(.hidden)
                footer
            }
            .padding(.horizontal, 32)
            .padding(.top, 46)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.canvas)
        }
        .foregroundStyle(Palette.ink)
        .font(.system(size: 13))
        .tint(Palette.accent)
        .preferredColorScheme(.light)
        .ignoresSafeArea()
        .alert("暂时无法完成设置", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("知道了") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                BrandMark().frame(width: 35, height: 35)
                Text("ScrollSplit").font(.system(size: 19, weight: .bold, design: .rounded))
            }
            .padding(.bottom, 8)
            Text("滚动，自有方向。")
                .font(.system(size: 11)).foregroundStyle(Palette.muted)
                .padding(.leading, 45)
            VStack(spacing: 7) {
                ForEach(Page.allCases, id: \.self) { item in
                    Button { page = item } label: {
                        HStack(spacing: 11) {
                            Image(systemName: item.icon).font(.system(size: 16, weight: .medium)).frame(width: 20)
                            Text(item.rawValue).fontWeight(page == item ? .semibold : .medium)
                            Spacer()
                            if page == item { Circle().fill(Palette.accent).frame(width: 5, height: 5) }
                        }
                        .foregroundStyle(page == item ? Palette.accent : Palette.muted)
                        .padding(.horizontal, 13).padding(.vertical, 13)
                        .background(page == item ? Palette.accent.opacity(0.09) : .clear,
                                    in: RoundedRectangle(cornerRadius: 11))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(page == item ? .isSelected : [])
                }
            }
            .padding(.top, 42)
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "leaf").font(.system(size: 20)).foregroundStyle(Palette.green)
                Text("轻一点，顺一点。").fontWeight(.medium)
                Text("保留原有速度与手感，\n只让方向更合心意。")
                    .font(.system(size: 11)).foregroundStyle(Palette.muted).lineSpacing(5)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
            HStack {
                Text("macOS").foregroundStyle(Palette.muted)
                Spacer()
                Text("VERSION \(AppVersion.display)").font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.muted)
            }.font(.system(size: 10)).padding(.top, 21)
        }
        .padding(.horizontal, 20).padding(.top, 56).padding(.bottom, 23)
        .frame(width: 206)
        .background(Color(red: 0.945, green: 0.949, blue: 0.970))
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 7) {
                Text(page == .control ? "YOUR SCROLL, YOUR WAY" : page == .preferences ? "MAKE IT YOURS" : "A LITTLE HELP")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(2).foregroundStyle(Palette.muted)
                Text(page.rawValue).font(.system(size: 27, weight: .bold))
            }
            Spacer()
            StateBadge(state: model.state)
        }
        .padding(.bottom, 24)
        .overlay(alignment: .bottom) { Rectangle().fill(Palette.line).frame(height: 1) }
    }

    private var control: some View {
        Group {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("两种设备，各自顺手。")
                        .font(.system(size: 25, weight: .semibold))
                    Text("鼠标用熟悉的方向，触控板保留自然的手感。")
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Palette.accent.opacity(0.7))
                    .frame(width: 65, height: 65)
                    .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 20))
                    .rotationEffect(.degrees(8))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [
                Color(red: 0.91, green: 0.90, blue: 0.99),
                Color(red: 0.94, green: 0.95, blue: 1)
            ], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20))

            HStack(spacing: 16) {
                deviceCard(mouse: true)
                deviceCard(mouse: false)
            }
            VStack(spacing: 0) {
                settingRow(icon: "arrow.up.arrow.down.circle", title: "启用独立滚动", detail: model.state.detail) {
                    Toggle("启用独立滚动", isOn: Binding(get: { model.enabled }, set: model.setEnabled))
                        .labelsHidden().toggleStyle(.switch).controlSize(.regular)
                }
                Divider().padding(.leading, 55)
                settingRow(icon: "arrow.left.arrow.right", title: "鼠标横向滚动也反转",
                           detail: "横向滚轮与纵向保持相同习惯") {
                    Toggle("鼠标横向滚动也反转", isOn: Binding(get: { model.horizontal }, set: model.setHorizontal))
                        .labelsHidden().toggleStyle(.switch).controlSize(.small)
                        .disabled(!model.enabled)
                }
            }
            .padding(.horizontal, 18).card()
            permissionBanner
        }
    }

    private func deviceCard(mouse: Bool) -> some View {
        let tint = mouse ? Palette.accent : Palette.green
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(mouse ? "MOUSE" : "TRACKPAD")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(1.7).foregroundStyle(Palette.muted)
                Spacer()
                Text(mouse ? "独立控制" : "跟随系统")
                    .font(.system(size: 9, weight: .medium)).foregroundStyle(tint)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(tint.opacity(0.07), in: Capsule())
            }
            DeviceIllustration(mouse: mouse)
                .frame(height: 96).frame(maxWidth: .infinity)
                .padding(.top, 5).padding(.bottom, 4)
                .accessibilityHidden(true)
            HStack(alignment: .firstTextBaseline) {
                Text(mouse ? "鼠标" : "触控板").font(.system(size: 17, weight: .semibold))
                Spacer()
                Text(mouse ? mouseDirection : trackpadDirection)
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(tint)
            }
            Text(mouse ? mouseCaption : "连续滚动、惯性与多指手势保持原样")
                .font(.system(size: 10)).foregroundStyle(Palette.muted).padding(.top, 7)
                .lineLimit(2).frame(height: 27, alignment: .topLeading)
        }
        .padding(17).card()
    }

    private var mouseDirection: String {
        if !model.enabled { return "跟随系统" }
        if model.state != .active { return "等待就绪" }
        return model.natural == nil ? "方向已反转" : "传统滚动"
    }
    private var mouseCaption: String {
        model.state == .active ? "只改变方向，保留滚轮原有幅度与速度" : "目标：鼠标使用传统滚动方向"
    }
    private var trackpadDirection: String {
        if let natural = model.natural { return natural ? "自然滚动" : "非自然滚动" }
        return "系统原方向"
    }

    private var permissionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: model.trusted ? "checkmark.shield" : "lock.shield")
                .font(.system(size: 20)).foregroundStyle(model.trusted ? Palette.green : Palette.amber)
            VStack(alignment: .leading, spacing: 5) {
                Text(model.trusted ? "辅助功能已授权" : "还差一步：允许辅助功能")
                    .font(.system(size: 12, weight: .semibold))
                Text(model.trusted ? "关闭窗口后，ScrollSplit 会继续在菜单栏运行。" : "授权后自动生效，你可以随时暂停或退出。")
                    .font(.system(size: 10)).foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 4)
            Button(model.trusted ? "查看权限" : "去授权  ↗") { model.openPermissions() }
                .buttonStyle(SoftButtonStyle(primary: !model.trusted))
        }
        .padding(14)
        .background((model.trusted ? Palette.green : Palette.amber).opacity(0.055),
                    in: RoundedRectangle(cornerRadius: 13))
    }

    private var preferences: some View {
        Group {
            sectionLabel("日常使用", subtitle: "让 ScrollSplit 按你的习惯工作。")
            VStack(spacing: 0) {
                settingRow(icon: "power", title: "登录时自动启动", detail: "登录 Mac 后自动恢复独立滚动") {
                    Toggle("登录时自动启动", isOn: Binding(get: { model.loginEnabled }, set: model.setLogin))
                        .labelsHidden().toggleStyle(.switch)
                }
                if model.loginNeedsApproval {
                    HStack {
                        Text("登录项等待系统批准").foregroundStyle(Palette.amber)
                        Spacer()
                        Button("前往登录项") { model.openLoginSettings() }.buttonStyle(SoftButtonStyle())
                    }.padding(.bottom, 15)
                }
                Divider().padding(.leading, 55)
                settingRow(icon: "macwindow", title: "登录启动时显示窗口",
                           detail: "手动打开应用始终显示窗口；首次安装或升级后也会显示") {
                    Toggle("登录启动时显示窗口", isOn: Binding(get: { model.showWindowOnLogin }, set: model.setShowWindowOnLogin))
                        .labelsHidden().toggleStyle(.switch)
                }
                Divider().padding(.leading, 55)
                settingRow(icon: "menubar.rectangle", title: "菜单栏实时状态",
                           detail: "运行中、已暂停或待授权，抬眼就能看到") {
                    Text("始终显示").font(.system(size: 11)).foregroundStyle(Palette.muted)
                }
            }.padding(.horizontal, 18).card()
            sectionLabel("系统与权限", subtitle: "两种设备的独立方向，建立在系统自然滚动之上。")
            VStack(spacing: 0) {
                settingRow(icon: "hand.draw", title: "系统自然滚动",
                           detail: model.natural == true ? "已开启，符合推荐设置" : "请保持系统“自然滚动”开启") {
                    Button("系统设置  ↗") { model.openTrackpadSettings() }.buttonStyle(SoftButtonStyle())
                }
                Divider().padding(.leading, 55)
                settingRow(icon: "lock.shield", title: "辅助功能权限",
                           detail: model.trusted ? "已允许 ScrollSplit 修改滚轮方向" : "尚未授权，滚轮方向暂不修改") {
                    Button(model.trusted ? "查看权限" : "去授权  ↗") { model.openPermissions() }
                        .buttonStyle(SoftButtonStyle(primary: !model.trusted))
                }
                Divider().padding(.leading, 55)
                settingRow(icon: "arrow.clockwise", title: "重新连接滚动服务",
                           detail: "当授权后仍未生效，或唤醒后出现异常时使用") {
                    Button("重新连接") { model.reconnect() }.buttonStyle(SoftButtonStyle())
                }
            }.padding(.horizontal, 18).card()
            sectionLabel("版本与安装", subtitle: "当前版本 \(AppVersion.current) · 支持覆盖安装，保留已有设置。")
            VStack(spacing: 0) {
                settingRow(icon: "shippingbox", title: model.isInstalled ? "已安装到应用程序" : "当前从临时位置运行",
                           detail: model.isInstalled ? "以后从“应用程序”打开这一份即可" : "请拖入 Applications，再从“应用程序”打开") {
                    Button("在访达中显示") { model.revealApplication() }.buttonStyle(SoftButtonStyle())
                }
                Divider().padding(.leading, 55)
                Text("2.1 更新：修复安装后旧副本拦截启动、隐藏与最小化窗口恢复，并让窗口回到当前屏幕。")
                    .font(.system(size: 11)).foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 16).lineSpacing(4)
            }.padding(.horizontal, 18).card()
            HStack(spacing: 12) {
                Image(systemName: "externaldrive").foregroundStyle(Palette.accent)
                Text("升级后如权限未生效，请在辅助功能中移除旧条目，再添加当前应用。")
                    .font(.system(size: 11)).foregroundStyle(Palette.muted).lineSpacing(4)
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.accent.opacity(0.045), in: RoundedRectangle(cornerRadius: 13))
        }
    }

    private var guide: some View {
        Group {
            sectionLabel("三步，回到顺手的感觉。", subtitle: "设置一次，之后交给菜单栏里的 ScrollSplit。")
            VStack(alignment: .leading, spacing: 24) {
                guideStep("01", "安装或覆盖升级", "先退出旧版，把新版拖到 Applications 并选择“替换”。复制完成后双击安装包中的“打开已安装版本”，或从“应用程序”打开。")
                guideStep("02", "保持自然滚动开启", "在系统触控板设置中开启“自然滚动”，鼠标的方向由 ScrollSplit 反转。")
                guideStep("03", "授予辅助功能权限", "前往“隐私与安全性 → 辅助功能”允许 ScrollSplit。状态会自动更新。")
            }.padding(22).card()
            sectionLabel("试试手感", subtitle: "在下面的区域分别使用鼠标滚轮和触控板。")
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(1...8, id: \.self) { index in
                        HStack(spacing: 14) {
                            Text(String(format: "%02d", index))
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundStyle(Palette.accent.opacity(0.5))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(index == 1 ? "向下滚动，看看下一张卡片。" : index == 8 ? "到这里了，方向合你心意吗？" : "原来的速度，熟悉的节奏。")
                                    .font(.system(size: 12, weight: .medium))
                                Text("SCROLL TEST / \(index) OF 8")
                                    .font(.system(size: 9, design: .monospaced)).foregroundStyle(Palette.muted)
                            }
                            Spacer()
                            Image(systemName: "arrow.down").foregroundStyle(Palette.accent.opacity(0.5))
                        }.padding(16).background(.white, in: RoundedRectangle(cornerRadius: 10))
                    }
                }.padding(12)
            }
            .frame(height: 158)
            .background(Palette.accent.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
            Text("适合普通滚轮鼠标。Magic Mouse、连续滚动鼠标与部分第三方驱动可能无法分离；如使用其他滚动工具，请暂停其方向接管功能。")
                .font(.system(size: 11)).foregroundStyle(Palette.muted).lineSpacing(5)
            Text("退出即恢复系统行为。卸载前关闭登录启动，再将应用移到废纸篓。")
                .font(.system(size: 11)).foregroundStyle(Palette.muted)
        }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Circle().fill(model.state == .active ? Palette.green : Palette.muted).frame(width: 5, height: 5)
            Text("轻量运行 · 不添加平滑动画").font(.system(size: 10)).foregroundStyle(Palette.muted)
            Spacer()
            if model.natural == false {
                Button("开启系统自然滚动 ↗") { model.openTrackpadSettings() }
                    .font(.system(size: 10)).buttonStyle(.plain).foregroundStyle(Palette.amber)
            } else {
                Text("Made for your Mac").font(.system(size: 10)).foregroundStyle(Palette.muted.opacity(0.7))
            }
        }
        .padding(.top, 14)
        .overlay(alignment: .top) { Rectangle().fill(Palette.line).frame(height: 1) }
    }

    private func sectionLabel(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 18, weight: .semibold))
            Text(subtitle).font(.system(size: 12)).foregroundStyle(Palette.muted)
        }
    }

    private func settingRow<Control: View>(icon: String, title: String, detail: String,
                                          @ViewBuilder control: () -> Control) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(Palette.muted).frame(width: 25)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.system(size: 12, weight: .medium))
                Text(detail).font(.system(size: 10)).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            control()
        }.padding(.vertical, 14)
    }

    private func guideStep(_ number: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number).font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.accent).frame(width: 32, height: 32)
                .background(Palette.accent.opacity(0.075), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 7) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(text).font(.system(size: 11)).foregroundStyle(Palette.muted).lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BrandMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [Color(red: 0.49, green: 0.44, blue: 0.97),
                                             Palette.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: "arrow.up.arrow.down").font(.system(size: 19, weight: .semibold)).foregroundStyle(.white)
        }
    }
}

private struct StateBadge: View {
    let state: ScrollState
    private var color: Color { state == .active ? Palette.green : state == .paused ? Palette.muted : Palette.amber }
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(state.title).font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(color).padding(.horizontal, 12).padding(.vertical, 8)
        .background(color.opacity(0.075), in: Capsule())
        .accessibilityLabel("当前状态：\(state.title)")
    }
}

private struct DeviceIllustration: View {
    let mouse: Bool
    var body: some View {
        ZStack {
            Ellipse().fill((mouse ? Palette.accent : Palette.green).opacity(0.055))
                .frame(width: 170, height: 77).offset(y: 12)
            if mouse {
                Capsule()
                    .fill(LinearGradient(colors: [.white, Color(red: 0.94, green: 0.94, blue: 0.98)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Capsule().stroke(Color(red: 0.81, green: 0.81, blue: 0.9), lineWidth: 1))
                    .frame(width: 65, height: 96)
                    .shadow(color: Palette.accent.opacity(0.11), radius: 8, x: 3, y: 8)
                Rectangle().fill(Palette.accent.opacity(0.15)).frame(width: 1, height: 35).offset(y: -29)
                Capsule().fill(Palette.accent.opacity(0.7)).frame(width: 6, height: 17).offset(y: -20)
                Image(systemName: "arrow.down").font(.system(size: 23, weight: .light))
                    .foregroundStyle(Palette.accent.opacity(0.65)).offset(x: 61, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 13)
                    .fill(LinearGradient(colors: [.white, Color(red: 0.91, green: 0.95, blue: 0.94)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(red: 0.75, green: 0.83, blue: 0.81), lineWidth: 1))
                    .frame(width: 135, height: 85)
                    .shadow(color: Palette.green.opacity(0.09), radius: 7, x: 3, y: 7)
                HStack(spacing: 9) {
                    Capsule().fill(Palette.green.opacity(0.12)).frame(width: 9, height: 31)
                    Capsule().fill(Palette.green.opacity(0.12)).frame(width: 9, height: 31)
                }.offset(y: 6)
                Image(systemName: "arrow.up").font(.system(size: 21, weight: .light))
                    .foregroundStyle(Palette.green.opacity(0.6)).offset(y: -7)
            }
        }
    }
}

private struct SoftButtonStyle: ButtonStyle {
    var primary = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .foregroundStyle(primary ? .white : Palette.accent)
            .background(primary ? Palette.accent : Palette.accent.opacity(0.075),
                        in: RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

private extension View {
    func card() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.line.opacity(0.8), lineWidth: 1))
    }
}
