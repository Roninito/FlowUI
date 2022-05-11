//
//  File.swift
//  
//
//  Created by leerie simpson on 5/1/22.
//

import Foundation
import GameplayKit
import EventService


public class FlowComponent: GKComponent {
	
	enum FCEvents: String {
		case loaded = "com.flowgraph.loaded"
		case flowing = "com.flowgraph.flowing"
		case flowed = "com.flowgraph.flowed"
		case stateChanged = "com.flowgraph.stateChanged"
		case finishedFlowing = "com.flowgraph.finishedFlowing"
		case resetting = "com.flowgraph.resetting"
		case reset = "com.flowgraph.reset"
	}
	
	public override init() {
		super.init()
		load()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public func load() {
		if let es = Events.use() {
			es[] = Event(FCEvents.loaded.rawValue)
			es[] = Event(FCEvents.flowed.rawValue)
			es[] = Event(FCEvents.flowing.rawValue)
			es[] = Event(FCEvents.stateChanged.rawValue)
			es[] = Event(FCEvents.finishedFlowing.rawValue)
			es[] = Event(FCEvents.reset.rawValue)
			es[] = Event(FCEvents.resetting.rawValue)
		}
	}
}
