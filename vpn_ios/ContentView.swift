//
//  ContentView.swift
//  vpn_ios
//
//  Created by Zoraida Boetticher on 06.11.2024.
//

import SwiftUI
import UIKit
import Foundation

//import QtSwift

//class ViewController: UIViewController {
//    let settings = QSettings()
//
//    func saveIPAddress(_ ipAddress: String) {
//        settings.setValue(ipAddress, forKey: "lastSuccessfulConnection")
//    }
//
//    func getIPAddress() -> String? {
//        return settings.value(forKey: "lastSuccessfulConnection") as? String
//    }
//}

func log(_ message: String) {
    let logFile = "vpn_client.log"
    let logPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(logFile)
    
    if let logPath = logPath {
        let logMessage = "\(Date()): \(message)\n"
        if let fileHandle = FileHandle(forWritingAtPath: logPath.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(logMessage.data(using: .utf8)!)
        } else {
            do {
                try logMessage.write(to: logPath, atomically: true, encoding: .utf8)
            } catch {
                print("Ошибка записи лога: \(error)")
            }
        }
    }
}

enum ConnectionState {
    case disconnected
    case connecting
    case connected
}

let ipAddressRegex = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

func isValidIP(_ ipAddress: String) -> Bool {
    let range = NSRange(location: 0, length: ipAddress.utf16.count)
    let regex = try! NSRegularExpression(pattern: ipAddressRegex, options: [])
    return regex.firstMatch(in: ipAddress, options: [], range: range) != nil
}

struct ContentView: View {
    @State private var ipAddress = ""
    @State private var connectionState: ConnectionState = .disconnected
    
    var body: some View {
        VStack {
            
            Text("Сервер VPN")
                .padding()
            TextField("IP-адрес сервера VPN", text: $ipAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .disabled(connectionState != .disconnected)
                            .opacity(connectionState != .disconnected ? 0.5 : 1)
                            .foregroundColor(connectionState != .disconnected ?  Color(UIColor.systemGray) :  Color(UIColor.label))
                            .onChange(of: ipAddress) { newValue in
                                let filteredValue = newValue.filter { "0123456789.".contains($0) }
                                if filteredValue != newValue {
                                    ipAddress = filteredValue
                                }
                            }

            Button(action: {
                            switch connectionState {
                            case .disconnected:
                                log("Попытка подключения к VPN-серверу - \(ipAddress)")
                                if isValidIP(ipAddress){
                                    connectionState = .connecting
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        connectionState = .connected
                                        log("Подключение к VPN-серверу успешно - \(ipAddress)")
                                    }
                                }
                                else {
                                    log("Подключение к VPN-серверу не удалось - \(ipAddress)")
                                }
                                case .connected:
                                    connectionState = .connecting
                                    log("Попытка отключения от VPN-сервера - \(ipAddress)")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        connectionState = .disconnected
                                        log("Отключение от VPN-сервера успешно - \(ipAddress)")
                                    }
                                case .connecting:
                                    break
                                }
                        }) {
                            Text(connectionState != .disconnected ? "Отключиться" : "Подключиться")
                        }
                        .padding()
                        .background(connectionState == .connecting || ipAddress.isEmpty ? Color(UIColor.systemGray): Color(UIColor.systemBlue))
//                        .foregroundColor(Color(UIColor.systemBackground))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(connectionState == .connecting || ipAddress.isEmpty)

            Image(systemName: "circle.inset.filled")
                .foregroundColor(connectionState == .connected ? Color(UIColor.systemGreen) : connectionState == .connecting ? Color(UIColor.systemOrange) : Color(UIColor.systemGray))
                            .font(.largeTitle)
                            .padding()
                            .opacity(connectionState == .connecting ? 0.5 : 1)
            .animation(.easeInOut(duration: 0.5), value: connectionState)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        
    }
}
