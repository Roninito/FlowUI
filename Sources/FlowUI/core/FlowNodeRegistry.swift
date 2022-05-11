//
//  File.swift
//  
//
//  Created by leerie simpson on 5/1/22.
//

import Foundation
import ServiceKit
import SwiftUI


// Invokes a given closure with a buffer containing all metaclasses known to the Obj-C
/// runtime. The buffer is only valid for the duration of the closure call.
func withAllClasses<R>(_ body: (UnsafeBufferPointer<AnyClass>) throws -> R) rethrows -> R {
  	var count: UInt32 = 0
  	let classListPtr = objc_copyClassList(&count)
  	defer {
		free(UnsafeMutableRawPointer(classListPtr))
  	}
  	let classListBuffer = UnsafeBufferPointer(start: classListPtr, count: Int(count))
  	return try body(classListBuffer)
}




public class FlowNodeRegistry {
	public static var shared = FlowNodeRegistry()
	
//	public lazy var flowNodeNames = { flowNodeClasses.compactMap({ $0 as NSString }) }()
	
	public var flowNodeClasses: [NSString] = []
	
//	public lazy var flowListingView: some View = { FlowFinderView() }()
	
	private init() {
		withAllClasses ({
			flowNodeClasses = $0.compactMap { cls in
				cls as? Flowable.Type
			}.compactMap { c in
				"\(c)" as NSString
			}
		})
	}
	
	// Adds a node by Package.Classname, to a given graph, at the set position..
	public func addFlowNode(_ named: String, to graph: Graph, at position: CGPoint) {
//		let flowNode: FlowNode = NSClassFromString(named)
//		flowNode.position = position
//		graph.flowNodes.append(flowNode)
	}
}


struct FlowFinderView: View {
	@State var flowNodeNames: [NSString] = []
	@State var flowQuery: String = ""
	
	var body: some View {
		VStack {
			HStack {
				TextField("Find...", text: $flowQuery)
			}.onAppear() {
				flowNodeNames = FlowNodeRegistry.shared.flowNodeClasses
			}
			Divider()
			ForEach(flowNodeNames, id: \.self) { className in
				Button("\(className)" ) {
					
				}
			}
		}
	}
}
