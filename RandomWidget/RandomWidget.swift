//
//  RandomWidget.swift
//  RandomWidget
//
//  Created by Fadey Notchenko on 14.10.2022.
//

import WidgetKit
import SwiftUI
import Firebase
import FirebaseFirestore
import Kingfisher

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let date = Date()
        let next = Calendar.current.date(byAdding: .hour, value: 12, to: date)!
        
        fetchFromFirebase { memory in
            let entry = SimpleEntry(date: date, memory: memory)
            let timeline = Timeline(entries: [entry], policy: .after(next))
            completion(timeline)
        }
    }
    
    func fetchFromFirebase(_ completion: @escaping (WidgetMemory?) -> Void) {
        guard let id = Auth.auth().currentUser?.uid else {
            completion(nil)
            
            return
        }
        
        Firestore.firestore().collection(id).getDocuments { snap, _  in
            if let document = snap?.documents.randomElement() {
                let data = document.data()
                
                if let name = data["name"] as? String, let time = data["date"] as? Timestamp, let images = data["images"] as? [String] {
                    
                    let date = time.dateValue()
                    if let data = try? Data(contentsOf: URL(string: images.randomElement()!)!) {
                        completion(WidgetMemory(name: name, date: date, image: data))
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
}

struct WidgetMemory {
    var name: String
    var date: Date
    var image: Data
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    var memory: WidgetMemory?
}

struct RandomWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) private var family

    var body: some View {
        GeometryReader { reader in
            
            let size = reader.size
            
            if let memory = entry.memory{
                Image(uiImage: UIImage(data: memory.image)!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .overlay(alignment: .bottomTrailing) {
                        VStack(alignment: .trailing) {
                            Text(memory.name)
                                .widgetTextStyle(family)
                            
                            Text(memory.date, format: .dateTime.year().month().day())
                                .widgetTextStyle(family)
                        }
                        .padding(10)
                    }
            } else {
                Text("error")
            }
        }
    }
}

extension Text {
    func widgetTextStyle(_ family: WidgetFamily) -> some View {
        self
            .bold()
            .font(.system(size: family == .systemSmall ? 15 : 25))
            .foregroundColor(.white)
            .shadow(radius: 5)
    }
}

@main
struct RandomWidget: Widget {
    
    init() {
        FirebaseApp.configure()
        
        do {
            try Auth.auth().useUserAccessGroup("CQ3SGH4DSY.FN.Memories")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    let kind: String = "RandomWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RandomWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemLarge, .systemExtraLarge])
        .configurationDisplayName("Cлучайное воспоминание")
        .description("Каждые 12 часов случаным образом выбирается одно из воспоминаний")
    }
}
