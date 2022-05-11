//
//  File.swift
//  
//
//  Created by leerie simpson on 4/30/22.
//

import Foundation
import SwiftUI

public class Inlet: NSObject, FlowSocket, ObservableObject {
	public var owner: Flowable
	public var name: String = ""
	public var pipes:  [FlowConnectable] = []
	public var socketType: FlowSocketType = .inlet
	public var dataType: FlowDataType = .string
	
	@Published public var position: CGPoint = .zero
	@Published var color: Color = .yellow
	
	public var value: Any? = nil {
		didSet {
			owner.flow()
		}
	}
	
	public init(flowNode: Flowable) {
		self.owner = flowNode
	}
}


public struct FlowInletSocketHandleView: View {
	@State var hasConnection = false
	@State var isDragSource = false
	@ObservedObject public var inlet: Inlet
	public var body: some View {
		ZStack {
			if hasConnection {
				Circle()
					.stroke(lineWidth: 1)
					.frame(width: 10, height: 10)
					.foregroundColor(inlet.dataType.asColor())
			}
			if isDragSource {
				Circle()
					.stroke(lineWidth: 1)
					.frame(width: 12, height: 12)
					.foregroundColor(.blue)
			}
			Circle()
				.foregroundColor(inlet.dataType.asColor())
				.frame(width: 7, height: 7)
		}
		.onAppear() {
			let graph = inlet.owner.owner as! Graph
			graph.$dragSource.sink { sock in
				if sock as? Inlet == inlet { isDragSource = true }
				else { isDragSource = false }
			}.store(in: &graph.subscriptions)
			
			inlet.objectWillChange.sink { outl in
				hasConnection =  inlet.pipes.isEmpty == false
				print("Inlet has connection: \(hasConnection)")
			}
			.store(in: &graph.subscriptions)
		}
	}
}

public struct FlowOutletSocketHandleView: View {
	@State var hasConnection = false
	@State var isDragSource = false
	@ObservedObject public var outlet: Outlet
	public var body: some View {
		ZStack {
			if hasConnection {
				Circle()
					.stroke(lineWidth: 1)
					.frame(width: 10, height: 10)
					.foregroundColor(outlet.dataType.asColor())
			}
			if isDragSource {
				Circle()
					.stroke(lineWidth: 3)
					.frame(width: 12, height: 12)
					.foregroundColor(.blue)
			}
			Circle()
				.foregroundColor(outlet.dataType.asColor())
				.frame(width: 7, height: 7)
		}
		.onAppear() {
			let graph = outlet.owner.owner as! Graph
			
			graph.$dragSource.sink { sock in
				if sock as? Outlet == outlet { isDragSource = true }
				else { isDragSource = false }
			}.store(in: &graph.subscriptions)
			
			outlet.objectWillChange.sink { outl in
				hasConnection =  outlet.pipes.isEmpty == false
				print("Outlet has connection: \(hasConnection)")
			}
			.store(in: &graph.subscriptions)
		}
	}
}


public class Outlet: NSObject, FlowSocket, ObservableObject {
	public var owner: Flowable
	public var name: String = ""
	@Published public var position: CGPoint = .zero
	@Published public var pipes: [FlowConnectable] = []
	public var socketType: FlowSocketType = .outlet
	public var dataType: FlowDataType = .string
	@Published var color: Color = .yellow

	public var value: Any? = nil {
		didSet {
			if value != nil {
				for pipe in pipes {
					pipe.flow()
				}
			}
		}
	}
	
	public init(flowNode: Flowable) {
		self.owner = flowNode
	}
}


public struct InletView: View {
	@ObservedObject var inlet: Inlet
	public var body: some View {
		HStack {
			FlowInletSocketHandleView(inlet: inlet)
				.onTapGesture(count: 3) {
					inlet.pipes.forEach({ ($0 as? FlowPipe)?.destroy() })
				}
			.onLongPressGesture() {
				if let outlet = inlet.owner.owner.dragSource as? Outlet {
					if inlet.dataType != outlet.dataType { return }
					let newPipe = FlowPipe(source: outlet, destination: inlet)
					
					inlet.owner.owner.flowPipes.append(newPipe)
					outlet.pipes.append(newPipe)
					inlet.pipes.append(newPipe)
					print("Laying pipe from an outlet. \nPipes: \(inlet.owner.owner.flowPipes.count)")
					(inlet.owner.owner as? Graph)?.objectWillChange.send()
					inlet.owner.owner.dragSource = nil
					inlet.objectWillChange.send()
					outlet.objectWillChange.send()
				}
				else {
					inlet.owner.owner.dragSource = inlet
					inlet.objectWillChange.send()
					print("Setting inlet as drag source.")
				}
			}
			Text(inlet.name).foregroundColor(Color("flowNodeLabelColor"))
			Spacer()
		}
		.background(GeometryReader() { reader in
			Color.clear.onAppear() {
				let frame = reader.frame(in: .global)
				inlet.position = CGPoint(x: frame.minX, y: frame.midY)
				print("drawing inlet background")
			}
		})
		.padding(0)
	}
}


public struct OutletView: View {
	@ObservedObject var outlet: Outlet
	@State var index = 0
	@State var selectedPipe: FlowPipe!
	public var body: some View {
		HStack {
			Spacer()
			Text(outlet.name).foregroundColor(Color("flowNodeLabelColor"))
			FlowOutletSocketHandleView(outlet: outlet)
				.onTapGesture(count: 2){
					if index > outlet.pipes.count  {
						index = 0
						selectedPipe?.isSelected = false
						print("Unselecting all pipes.")
						index = 1
						return
					}
					if let previousSelected = selectedPipe {
						previousSelected.isSelected = false
					}
					if index - 1 >= 0 {
						selectedPipe = outlet.pipes[index - 1] as? FlowPipe
						selectedPipe.isSelected = true
						print("Pipe selection changed to index: \(index)")
						index += 1
						return
					}
					
					index += 1
				}
				.onLongPressGesture(perform: {
					if let inlet = outlet.owner.owner.dragSource as? Inlet {
						if inlet.dataType != outlet.dataType { return }
						let newPipe = FlowPipe(source: outlet, destination: inlet)
						inlet.owner.owner.flowPipes.append(newPipe)
						inlet.pipes.append(newPipe)
						outlet.pipes.append(newPipe)
						print("Laying Pipe from an inlet. \nPipes: \(outlet.owner.owner.flowPipes.count)")
						(outlet.owner.owner as? Graph)?.objectWillChange.send()
						outlet.owner.owner.dragSource = nil
						inlet.objectWillChange.send()
						outlet.objectWillChange.send()
					}
					else {
						outlet.owner.owner.dragSource = outlet
					}
					print("Setting outlet as drag source.")
				})
		}
		.background(GeometryReader() { reader in
			Color.clear.onAppear() {
				let frame = reader.frame(in: .global)
				outlet.position = CGPoint(x: frame.maxX, y: frame.midY)
			}
		})
		.padding(0)
	}
}
