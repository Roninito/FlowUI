//
//  File.swift
//  
//
//  Created by leerie simpson on 4/30/22.
//

import Foundation
import SwiftUI


public class FlowNode: NSObject, Flowable, NSSecureCoding, ObservableObject {
	public static var supportsSecureCoding: Bool = true
	public var owner: FlowGraphable
	@Published public var inlets: [Inlet] = []
	@Published public var outlets: [Outlet] = []
	@Published public var state: FlowState = .resting
	@Published public var position: CGPoint = .zero
	@Published public var flowNodeName: String = ""
	@Published public var reportedHeight: CGFloat = 0
	@Published public var reportedWidth: CGFloat = 0
	
	public init(graph: FlowGraphable, at position: CGPoint) {
		self.owner = graph
		self.position = position
	}
	
	/// Called by the graph and during reset to update the node with data necessary for it's activity.
	public func load() { }
	
	/// When the node is ready to run, perform its activities in this method. Always dispatch to main queue from this method any activity that affest the external system. These methods run on the graphs flowqueue.
	open func activity(flowNode: Flowable) {}
	
	/// Provide a view to manipulate the properties of this node and offer user output when necessary.
	open func controls() -> AnyView {
		AnyView(EmptyView())
	}
	
	open func header() -> AnyView {
		AnyView(
			VStack {
				HStack {
					Text(flowNodeName)
						.font(.custom("Sudo", size: 16))
						.foregroundColor(Color("flowNodeHeaderLabelColor"))
						.fontWeight(.heavy)
						.opacity(0.7)
						.padding(5)
						.padding(.bottom, -5)
					Spacer()
				}.padding(0)
				Divider().padding(0)
			}
				.padding(0)
				.background(Color("flowNodeHeaderBackgroundColor"))
		)
	}
	
	open func footer() -> AnyView {
		AnyView(Color.clear.frame(width: 5, height: 5))
	}
	
	public func outletViews() -> some View {
		VStack {
			ForEach(outlets, id: \.self) { out in
				OutletView(outlet: out)
			}
		}.padding(0).padding(.trailing, 0)
	}
	
	public func inletViews() -> some View {
		VStack {
			ForEach(inlets, id: \.self) { inl in
				InletView(inlet: inl)
			}
		}.padding(0).padding(.leading, 0)
	}
	
	public func flowView() -> AnyView {
		AnyView(
			VStack(alignment: .leading) {
				header()
				inletViews().foregroundColor(.gray)
				outletViews().foregroundColor(.gray)
				Divider()
				Form {
					controls()
				}
				.padding(.horizontal, 10)
				
				footer()
			}
				.padding(0)
				.background(Rectangle()
					.cornerRadius(5)
					.foregroundColor(Color("flowNodeColor"))
					.blendMode(.hardLight)
				)
				.frame(width: 300)
				.cornerRadius(5)
				.position(position)
				.font(.custom("Monospaceland Extra Light", size: 10).weight(.ultraLight))
			
		)
	}
	
	public func encode(with coder: NSCoder) {
		coder.encode(inlets, forKey: "inlets")
		coder.encode(outlets, forKey: "outlets")
		coder.encode(owner, forKey: "owner")
		coder.encode(state.rawValue, forKey: "state")
	}
	
	public required init?(coder: NSCoder) {
		self.owner = coder.decodeObject(of: [Graph.self], forKey: "owner") as! Graph
		self.inlets = coder.decodeObject(of: [Inlet.self, NSArray.self], forKey: "inlets") as! [Inlet]
		self.outlets = coder.decodeObject(of: [Outlet.self, NSArray.self], forKey: "outlets") as! [Outlet]
		self.state = FlowState(rawValue: coder.decodeInteger(forKey: "state"))!
		super.init()
	}
	
	public func flow() {
		owner.flowQueue.async {
			if self.allInletsFinished() {
				if self.state != .failed {
					self.state = .finished
					return
				}
				self.process(self)
			}
			else {
				self.state = .waiting
			}
		}
	}
	
	/// Reset values, data and change to resting state.
	public func reset() {
		owner.flowQueue.async {
			self.load()
			self.state = .resting
		}
	}
	
	public func process(_ owner: Flowable) {
		self.activity(flowNode: self)
	}
	
	fileprivate func allInletsFinished() -> Bool {
		for inlet in inlets {
			if inlet.pipes.isEmpty { continue }
			let firstPipe = inlet.pipes.first!
			if firstPipe.source!.owner.state == .waiting { return false }
			if firstPipe.source!.owner.state == .finished { continue }
			if firstPipe.source!.owner.state == .failed { self.state = .failed }
		}
		return true
	}
}


struct FlowNodeView: View {
	@ObservedObject var flowNode: FlowNode
	
	var simpleDrag: some Gesture {
		DragGesture()
			.onChanged { value in
				let graph = flowNode.owner as! Graph
				if graph.flowNodeMoveStartPos == nil {
					graph.flowNodeMoveStartPos = flowNode.position
					graph.flowNodeGrabOffset.x = graph.flowNodeMoveStartPos.x - value.startLocation.x
					graph.flowNodeGrabOffset.y = graph.flowNodeMoveStartPos.y - value.startLocation.y
					
					graph.inletDragOffsetPositions = []
					flowNode.inlets.forEach({
						graph.inletStartPositions.append($0.position)
						graph.inletDragOffsetPositions.append(CGPoint(x: $0.position.x - value.startLocation.x, y: $0.position.y - value.startLocation.y) )
					})
					
					graph.outletDragOffsetPositions = []
					flowNode.outlets.forEach({
						graph.outletStartPositions.append($0.position)
						graph.outletDragOffsetPositions.append(CGPoint(x: $0.position.x - value.startLocation.x, y: $0.position.y - value.startLocation.y))
					})
				}
				
				flowNode.position.x = value.location.x + graph.flowNodeGrabOffset.x
				flowNode.position.y = value.location.y + graph.flowNodeGrabOffset.y
				
				var index = 0
				flowNode.outlets.forEach({ otl in
					otl.position.x = value.location.x + graph.outletDragOffsetPositions[index].x
					otl.position.y = value.location.y + graph.outletDragOffsetPositions[index].y
					index += 1
				})
				
				index = 0
				flowNode.inlets.forEach({ inl in
					inl.position.x = value.location.x + graph.inletDragOffsetPositions[index].x
					inl.position.y = value.location.y + graph.inletDragOffsetPositions[index].y
					index += 1
				})
			}
			.onEnded { value in
				let graph = flowNode.owner as! Graph
				graph.resizeGraph()
				flowNode.position.x = graph.flowNodeMoveStartPos.x + value.translation.width
				flowNode.position.y = graph.flowNodeMoveStartPos.y + value.translation.height
				
				var index = 0
				flowNode.inlets.forEach({
					$0.position.x = graph.inletStartPositions[index].x + value.translation.width
					$0.position.y = graph.inletStartPositions[index].y + value.translation.height
					index += 1
				})
				index = 0
				flowNode.outlets.forEach({
					$0.position.x = graph.outletStartPositions[index].x + value.translation.width
					$0.position.y = graph.outletStartPositions[index].y + value.translation.height
					index += 1
				})
				print("Drag ended: Inlets and Outlets will change.")
				graph.flowNodeMoveStartPos = nil
				graph.lastDragPoint = nil
				graph.outletStartPositions = []
				graph.inletStartPositions = []
			}
	}
	
	var body: some View {
		GeometryReader { geo in
			flowNode.flowView().padding(5).gesture(simpleDrag).onAppear() {
				flowNode.reportedWidth = geo.frame(in: .global).width
				flowNode.reportedHeight = geo.frame(in: .global).height
				print("Node drawn, updating size (\(flowNode.reportedWidth), \(flowNode.reportedHeight)")
			}
		}
	}
}
