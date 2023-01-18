//
//  SettingsView.swift
//  PGPro
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import SPAlert
import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) var openURL

    @State private var exportingKeychain: Bool = false
    @State private var keychainExportFailed: Bool = false
    @State private var keychainExportFailedErrorMessage: String? = nil
    @State private var keychainExportURL: URL? = nil
    
    @State private var presentingKeychainExport: Bool = false

    private func exportKeychain() {
        exportingKeychain = true

        let result = Contact.exportAll()
        switch result {
        case .success(let url):
            Log.i("Export successful: url = \(url)")
            exportingKeychain = false
            keychainExportURL = url
            presentingKeychainExport = true

        case .failure(let error):
            Log.e(error)
            exportingKeychain = false
            keychainExportFailedErrorMessage = error.localizedDescription
            keychainExportFailed = true
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Data") {
                    Group {
                        Button {
                            exportKeychain()
                        } label: {
                            Label("Export Keychain", systemImage: "square.and.arrow.up.fill")
                                .labelStyle(ColorfulIconLabelStyle(color: .green))
                        }
                    }
                    .foregroundColor(Color.primary)
                }

                Section("Preferences") {
                    Group {
                        NavigationLink {
                            AppearancePreferenceView()
                        } label: {
                            Label("Appearance", systemImage: "paintpalette.fill")
                                .labelStyle(ColorfulIconLabelStyle(color: .pink))
                        }

                        NavigationLink {
                            MailIntegrationPreferenceView()
                        } label: {
                            Label("Mail Integration", systemImage: "envelope.fill")
                                .labelStyle(ColorfulIconLabelStyle(color: .blue))
                        }

                        NavigationLink {
                            AuthenticationPreferenceView()
                        } label: {
                            Label("Authentication", systemImage: AuthenticationPreferenceViewModel.symbolName)
                                .labelStyle(ColorfulIconLabelStyle(color: .orange))
                        }
                    }
                    .foregroundColor(Color.primary)
                }

                Section("Feedback") {
                    Group {
                        Button {
                            openURL(URL(string: "https://github.com/lucanaef/PGPro/issues")!)
                        } label: {
                            Label("Report Issue", systemImage: "ladybug.fill")
                                .labelStyle(ColorfulIconLabelStyle(color: .green))
                        }

                        Button {
                            openURL(URL(string: "https://testflight.apple.com/join/BNawuaNF")!)
                        } label: {
                            Label("Join Beta", systemImage: "airplane")
                                .labelStyle(ColorfulIconLabelStyle(color: .blue))
                        }

                        Button {
                            openURL(URL(string: "https://itunes.apple.com/app/id1481696997?action=write-review")!)
                        } label: {
                            Label("Please Rate PGPro", systemImage: "heart.fill")
                                .labelStyle(ColorfulIconLabelStyle(color: .red))
                        }
                    }
                    .foregroundColor(Color.primary)
                }

                Section("About") {
                    Group {
                        Button {
                            openURL(URL(string: "https://pgpro.app/faq/")!)
                        } label: {
                            Label("Frequently Asked Questions", systemImage: "questionmark.circle.fill")
                                .labelStyle(ColorfulIconLabelStyle(color: .mint))
                        }

                        Button {
                            openURL(URL(string: "https://github.com/lucanaef/PGPro")!)
                        } label: {
                            Label("Contribute on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                                .labelStyle(ColorfulIconLabelStyle(color: .green))
                        }

                        Button {
                            openURL(URL(string: "https://pgpro.app/privacypolicy/")!)
                        } label: {
                            Label("Privacy Policy", systemImage: "eye.slash.fill")
                                .labelStyle(ColorfulIconLabelStyle(color: .orange))
                        }

                        NavigationLink {
                            LicencesView()
                        } label: {
                            Label("Licenes", systemImage: "scroll.fill")
                                .labelStyle(ColorfulIconLabelStyle(color: .purple))
                        }
                    }
                    .foregroundColor(Color.primary)
                }
            }
            .navigationTitle("Settings")
            .SPAlert(isPresent: $exportingKeychain,
                     title: "Exporting Keychain...",
                     preset: .spinner)
            .SPAlert(isPresent: $keychainExportFailed,
                     title: "Export failed!",
                     message: keychainExportFailedErrorMessage,
                     duration: 2.0,
                     dismissOnTap: true,
                     preset: .error,
                     haptic: .error)
            .fileMover(isPresented: $presentingKeychainExport,
                       file: keychainExportURL) { result in
                switch result {
                case .success(let url):
                    Log.i("Keychain export file moved successfully to \(url.absoluteString)")
                case .failure(let error):
                    Log.e("Failed to move keychain export file! \(error.localizedDescription)")
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
