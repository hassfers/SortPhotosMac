//
//  ContentView.swift
//  sortPhotoMac
//
//  Created by Stefan Haßferter on 26.08.20.
//  Copyright © 2020 Stefan Haßferter. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var files: [URL] = []
    
    var body: some View {
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
                            //                            self.files.append(url)
                            self.files.append(contentsOf: self.parseFileURLRecursive(url: url))
                        }
                    }
                    return true
                })
                .overlay(Text("Drag your files here"))
            Text("\(files.count)")
            HStack{
                Button("Clear"){
                    self.files.removeAll()
                }
                Button("Start"){}
            }
            List(files,id: \.self){ file in
                Text("\(file)")
                if NSImage(contentsOfFile: file.path) != nil {
                    Image(nsImage: NSImage(contentsOfFile: file.path)!)
                        .resizable()
                        .scaledToFit()
                }
                //                Image(nsImage: NSImage(contentsOfFile: file.path)!)
                //                    .resizable()
                //                    .scaledToFit()
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
                        urls.append(url2)
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(files: [])
    }
}
