//
//  ContentView.swift
//  sortPhotoMac
//
//  Created by Stefan Haßferter on 26.08.20.
//  Copyright © 2020 Stefan Haßferter. All rights reserved.
//

import SwiftUI
import SwiftyImageIO
import KingfisherSwiftUI

struct ContentView: View {
    @State var files: [URL] = []
    @State var photos: [Photo] = []
    @State var outputRootPath: String = ""
    @State var isRunning: Bool = false

    @State var subDictionaryYear: Bool = true
    @State var subDictionaryMonth: Bool = false
    @State var subDictionaryDay: Bool = false
    @State var renameFile: Bool = false
    @State var currentFileNumber: Int = 0

    var body: some View {
        ZStack{
            VStack{
                Rectangle()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onDrop(of: ["public.file-url"], isTargeted: .constant(true), perform: { provider -> Bool in
                        print(provider.count)
                        provider.forEach { (innerProvider) in
                            innerProvider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                                guard
                                    let data = item as? Data,
                                    let url = URL(dataRepresentation: data, relativeTo: nil)
                                    else { return }
                                self.files.append(contentsOf: self.parseFileURLRecursive(url: url))
                            }
                        }
                        return true
                    })
                    .overlay(Text("Drag your files here"))
                Text("\(files.count) found")
                Text("\(photos.count) pictures scanned and sorted")
                Text("\(isRunning ? "running \(currentFileNumber)" : "stopped")")
                RootFilePathView(filePath: $outputRootPath)

                VStack {
                    Text("Subdictionaries")
                    HStack{
                        Toggle(isOn: $subDictionaryYear) {
                            Text("Year")
                        }
                        Toggle(isOn: $subDictionaryMonth) {
                            Text("Month")
                        }
                        Toggle(isOn: $subDictionaryDay) {
                            Text("Day")
                        }
                    }
                    Toggle(isOn: $renameFile) {
                        Text("rename file to dateString")
                    }
                }
                HStack{
                    Button("Clear"){
                        self.files.removeAll()
                        self.photos.removeAll()
                    }
                    Button("Start") {
                        self.isRunning = true
                        self.currentFileNumber = 0
                        DispatchQueue.main.async {
                            let config = SortConfiguration(subDictionaryYear: self.subDictionaryYear,
                                                           subDictionaryMonth: self.subDictionaryMonth,
                                                           subDictionaryDay: self.subDictionaryDay,
                                                           renameFile: self.renameFile,
                                                           rootPath: self.outputRootPath)

                            self.photos = self.files.map {
                                let photo = Photo(fileUrl: $0)
                                photo.generateNewPath(config: config)
                                self.currentFileNumber += 1
                                return photo
                            }
                            self.isRunning = false
                        }
                    }.disabled(outputRootPath.isEmpty || files.isEmpty)
                    Button("write to disk"){
                        self.isRunning = true
                        DispatchQueue.main.async {
                        self.photos.forEach { photo in
                                try? photo.moveToNewLocation()
                            }
                            self.isRunning = false
                        }
                    }.disabled(photos.isEmpty)
                }

                List(files, id: \.self){ file in
                    Text("\(file)")
                    Text("\(DateFormatter.parseEXIFDate(from: Photo.loadDateString(for: file)) ?? Date())")
                }
                Divider()
                List(photos, id: \.self){ photo in
                    Text("\(photo.processed.text)")
                    Text("\(photo.fileUrl)")
                    Text("\(photo.urlAfterSorting?.path ?? "")")
                    Text("\(photo.dateTime ?? Date())")
                }
            }
            .blur(radius: isRunning ? 0.5 : 0, opaque: false )
            .disabled(isRunning)
            if isRunning{
                ProgressIndicator()
                    .padding()
            }
        }
    }

    func parseFileURLRecursive(url: URL) ->  [URL] {
        guard url.isFileURL else { return [] }
        var urls: [URL] = []

        if url.hasDirectoryPath {
            do {
                let items = try FileManager.default.contentsOfDirectory(atPath: url.path)
                for item in items {
                    let url2 = URL(fileURLWithPath: item, relativeTo: url)
                    if url2.hasDirectoryPath {
                        urls.append(contentsOf: parseFileURLRecursive(url: url2))
                    } else {
                        if NSItemProvider(contentsOf: url2)?.hasItemConformingToTypeIdentifier("public.image") ?? false {
                            urls.append(url2)
                        }
                    }
                }
            } catch {
                // failed to read directory – bad permissions, perhaps?
                return []
            }
        } else {
            return [url]
        }
        return urls
    }

}

struct ProgressIndicator: NSViewRepresentable {

    typealias TheNSView = NSProgressIndicator
    var configuration = { (view: TheNSView) in }

    func makeNSView(context: NSViewRepresentableContext<ProgressIndicator>) -> NSProgressIndicator {
        let view = TheNSView()
        view.controlTint = .blueControlTint
        view.isIndeterminate = true
        view.style = .spinning
        view.startAnimation(nil)
        return view
    }

    func updateNSView(_ nsView: NSProgressIndicator, context: NSViewRepresentableContext<ProgressIndicator>) {
        configuration(nsView)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(files: [])
    }
}

extension Optional where Wrapped == String {
    var isEmpty: Bool {
        return (self ?? "").isEmpty
    }
}

struct RootFilePathView: View {
    @Binding var filePath: String
    var body: some View {
        HStack{
            TextField("Output Root Path", text: $filePath)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Open ... "){
                let dialog = NSOpenPanel();

                dialog.title                   = "Choose a dictionary";
                dialog.showsResizeIndicator    = true;
                dialog.showsHiddenFiles        = false;
                dialog.canChooseDirectories    = true;
                dialog.canCreateDirectories    = true;
                dialog.allowsMultipleSelection = false;

                if (dialog.runModal() == NSApplication.ModalResponse.OK) {
                    let result = dialog.url // Pathname of the file
                    if result?.hasDirectoryPath ?? false {
                        self.filePath = result?.path ?? ""
                    }
                } else {
                    // User clicked on "Cancel"
                    return
                }
            }
        } .padding()
    }
}
