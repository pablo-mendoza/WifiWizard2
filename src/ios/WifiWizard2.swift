import Foundation
import CoreLocation
import NetworkExtension
// import SystemConfiguration.CaptiveNetwork

@objc(WifiWizard2)
class WifiWizard2: CDVPlugin {
    
    let locationManager = CLLocationManager()

    // MARK: - Connect to WPA/WPA2 network
    @objc(iOSConnectNetwork:)
    func iOSConnectNetwork(command: CDVInvokedUrlCommand) {
        guard let options = command.argument(at: 0) as? [String: Any],
              let ssid = options["Ssid"] as? String,
              let password = options["Password"] as? String else {
            sendError("Missing SSID or Password", callbackId: command.callbackId)
            return
        }

        let config = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        config.joinOnce = false
        
        NEHotspotConfigurationManager.shared.apply(config) { error in
            if let error = error {
                self.sendError(error.localizedDescription, callbackId: command.callbackId)
            } else {
                self.sendOK(ssid, callbackId: command.callbackId)
            }
        }
    }

    // MARK: - Connect to Open network
    @objc(iOSConnectOpenNetwork:)
    func iOSConnectOpenNetwork(command: CDVInvokedUrlCommand) {
        guard let options = command.argument(at: 0) as? [String: Any],
              let ssid = options["Ssid"] as? String else {
            sendError("Missing SSID", callbackId: command.callbackId)
            return
        }

        let config = NEHotspotConfiguration(ssid: ssid)
        config.joinOnce = false

        NEHotspotConfigurationManager.shared.apply(config) { error in
            if let error = error {
                self.sendError(error.localizedDescription, callbackId: command.callbackId)
            } else {
                self.sendOK(ssid, callbackId: command.callbackId)
            }
        }
    }

    // MARK: - Disconnect
    @objc(iOSDisconnectNetwork:)
    func iOSDisconnectNetwork(command: CDVInvokedUrlCommand) {
        
        guard let options = command.argument(at: 0) as? [String: Any],
              let ssid = options["Ssid"] as? String else {
            sendError("Missing SSID", callbackId: command.callbackId)
            return
        }

        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
        sendOK(ssid, callbackId: command.callbackId)
    }

    // MARK: - Get Connected SSID
    @objc(getConnectedSSID:)
    func getConnectedSSID(command: CDVInvokedUrlCommand) {
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { network in
                guard let ssid = network?.ssid else {
                    self.sendError("SSID not available", callbackId: command.callbackId)
                    return
                }
                self.sendOK(ssid, callbackId: command.callbackId)
            }
        } else {
            // iOS < 14 fallback
            self.sendError("Not supported on this iOS version", callbackId: command.callbackId)
        }
    }

    // MARK: - Get Connected BSSID
    @objc(getConnectedBSSID:)
    func getConnectedBSSID(command: CDVInvokedUrlCommand) {
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { network in
                guard let bssid = network?.bssid else {
                    self.sendError("BSSID not available", callbackId: command.callbackId)
                    return
                }
                self.sendOK(bssid, callbackId: command.callbackId)
            }
        } else {
            // iOS < 14 fallback
            self.sendError("Not supported on this iOS version", callbackId: command.callbackId)
        }
    }

    // MARK: - Is WiFi Enabled (rough approximation)
    @objc(isWifiEnabled:)
    func isWifiEnabled(command: CDVInvokedUrlCommand) {
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { network in
                let isWifiAvailable = (network?.ssid != nil)
                self.sendOK(isWifiAvailable ? "1" : "0", callbackId: command.callbackId)
            }
        } else {
            // iOS < 14 fallback
            self.sendError("Not supported on this iOS version", callbackId: command.callbackId)
        }
    }

    // MARK: - Not supported
    @objc(setWifiEnabled:)
    func setWifiEnabled(command: CDVInvokedUrlCommand) {
        sendError("Not supported", callbackId: command.callbackId)
    }

    @objc(scan:)
    func scan(command: CDVInvokedUrlCommand) {
        sendError("Not supported", callbackId: command.callbackId)
    }

    @objc(disconnect:)
    func disconnect(command: CDVInvokedUrlCommand) {
        sendError("Not supported", callbackId: command.callbackId)
    }

    // MARK: - Helpers

    private func sendOK(_ message: String, callbackId: String) {
        let result = CDVPluginResult(status: .ok, messageAs: message)
        self.commandDelegate.send(result, callbackId: callbackId)
    }

    private func sendError(_ message: String, callbackId: String) {
        let result = CDVPluginResult(status: .error, messageAs: message)
        self.commandDelegate.send(result, callbackId: callbackId)
    }
}
