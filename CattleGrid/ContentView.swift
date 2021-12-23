//
//  ContentView.swift
//  CattleGrid
//
//  Created by Eric Betts on 4/10/20.
//  Copyright © 2020 Eric Betts. All rights reserved.
//

import SwiftUI


struct ContentView: View {
    @EnvironmentObject var tagStore: TagStore

    var body: some View {
        VStack(alignment: .center) {
            if (tagStore.readingAvailable) {
                MainScreen(tagStore: _tagStore)
            } else {
                Text("Either your phone doesn't have NFC, or the app's 'entitlements' aren't correctly signed")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(TagStore.shared)
    }
}

struct MainScreen: View {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    @EnvironmentObject var tagStore: TagStore
    @State private var searchText : String = ""

    var body: some View {
        VStack(alignment: .center) {
            if self.tagStore.lastPageWritten > 0 {
                HStack {
                    ProgressBar(value: tagStore.progress).frame(height: 20)
                    Text("\(tagStore.progress * 100, specifier: "%.2f")%")
                        .font(.subheadline)
                }
            }
            if self.tagStore.error != "" {
                Text(self.tagStore.error)
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            //File selector
            NavigationView {
                if (tagStore.files.count > 0) {
                    List(tagStore.files, id:\.path) { file in
                        ListElement(name: file.deletingPathExtension().lastPathComponent, selected: self.selected(file), isFile: (file.pathExtension == "bin"), cb: {
                            self.tagStore.load(file)
                        })
                    }
                    .navigationBarTitle(Text(title()), displayMode: .inline)
                    .navigationBarItems(
                        leading: Button(action: {
                            self.tagStore.load(self.tagStore.currentDir.deletingLastPathComponent())
                        }) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .disabled(atDocumentsDir())
                    )
                } else {
                    Text("No figures.").font(.headline)
                }
            }
            .onAppear(perform: self.tagStore.start)
            .onDisappear(perform: self.tagStore.stop)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.accentColor, lineWidth: 0.3)
            )
            //open in filza button
            Button(action: {
                guard let url: URL = URL(string: "filza:/" + self.documents.path) else { return }
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }) {
                Text("Open doc in Filza")
                    .foregroundColor(.blue)
                    .font(.callout)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
            //button to say 'go'
            Button(action: self.tagStore.scan) {
                Image(systemName: "arrow.down.doc")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:90, height:90)
                    .disabled(self.tagStore.selected == nil)
                    .padding()
            }
            .disabled(self.tagStore.selected == nil)
            Text("© Eric Betts 2020")
                .font(.footnote)
                .fontWeight(.light)
        }
        .padding()
    }

    func filtered(_ urls: [URL]) -> [URL] {
        return urls.filter{ self.searchText.isEmpty ? true : $0.lastPathComponent.contains(self.searchText) }
    }

    func selected(_ file: URL) -> Bool {
        return (file.lastPathComponent == self.tagStore.selected?.lastPathComponent)
    }

    func atDocumentsDir() -> Bool {
        return tagStore.currentDir.standardizedFileURL == self.documents.standardizedFileURL
    }

    func title() -> String {
        if (atDocumentsDir()) {
            return "CattleGrid"
        } else {
            return self.tagStore.currentDir.lastPathComponent
        }
    }
}

struct ListElement: View {
    let name : String
    let selected : Bool
    let isFile : Bool
    let cb : () -> Void

    var body: some View {
        HStack {
            if (isFile) {
                Text(name)
                    .foregroundColor(selected ? .primary : .secondary)
                    .onTapGesture(perform: cb)
            } else { // Folder
                HStack {
                    Text(name)
                    Text("")
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.systemBackground)) //'invisible' tappable target
                    Image(systemName: "chevron.right")
                }
                .onTapGesture(perform: cb)
            }
        }
    }
}
