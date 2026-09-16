import SwiftUI
@main struct BeHocVuiApp: App {
    @StateObject private var kho = KhoDuLieu()
    var body: some Scene { WindowGroup { ManHinhChinh().environmentObject(kho) } }
}
