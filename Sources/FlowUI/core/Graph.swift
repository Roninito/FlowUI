//
//  File.swift
//  
//
//  Created by leerie simpson on 4/30/22.
//

import Foundation
import EventService
import GameplayKit
import SwiftUI
import Combine


// todo : Support nscoding
public class Graph: NSObject, NSSecureCoding, ObservableObject, FlowGraphable {
	public static var supportsSecureCoding: Bool = true
	
	public var inletStartPositions: [CGPoint] = []
	public var outletStartPositions: [CGPoint] = []
	public var inletDragOffsetPositions: [CGPoint] = []
	public var outletDragOffsetPositions: [CGPoint] = []
	public var flowNodeMoveStartPos: CGPoint!
	public var flowNodeGrabOffset: CGPoint = .zero
	public var lastDragPoint: CGPoint!
	@Published public  var drawOffset: CGPoint = .zero
	@Published public var dragSource: FlowSocket!
	public var dragStarted: CGPoint!
	@Published public var graphSize: CGSize = CGSize(width: 800, height: 800)
	
	public var flowQueue: DispatchQueue!
	public var flowNodes: [Flowable] = []
	public var flowPipes: [FlowPipe] = []
	
	@Published public var name: String = ""
	@Published public var status: FlowState = .resting
	public var subscriptions = Set<AnyCancellable>()
	
	public func encode(with coder: NSCoder) {
		coder.encode(flowNodes, forKey: "nodes")
		coder.encode(name, forKey: "name")
		coder.encode(status.rawValue, forKey: "status")
	}
	
	public required init?(coder: NSCoder) {
		super.init()
		flowNodes = coder.decodeObject(of: [Graph.self], forKey: "graph") as! [Flowable]
		name = coder.decodeObject(of: [NSString.self], forKey: "name") as! String
		status = FlowState(rawValue: coder.decodeInteger(forKey: "status"))!
		load()
//		resizeGraph()
	}
	
	public override init() {
		super.init()
//		resizeGraph()
	}
	
	public func resizeGraph() {
		let sortedByX = flowNodes.sorted(by: { $0.position.x < $1.position.x })
		let minX = sortedByX.first!.position.x
		let maxX = sortedByX.last!.position.x
		let newWidth = maxX  - max(minX, 0) + 300 * 2
		let sortedByY = flowNodes.sorted(by: { $0.position.y < $1.position.y })
		let minY = sortedByY.first!.position.y
		let maxY = sortedByY.last!.position.y + sortedByY.last!.reportedHeight
		let newHeight = maxY - minY
		print("Resizing Graph:")
		print("\t minX: \(minX)")
		print("\t maxX: \(maxY)")
		
		print("\t minY: \(minY)")
		print("\t maxY: \(maxY)")
		
		print("\t Size Width: \(newWidth) Height: \(newHeight)")
		graphSize = CGSize(width: newWidth, height: newHeight)
	}
	public func load() {
		flowQueue = DispatchQueue(label: self.name)
		Events.use()?.raise(by: self, FlowComponent.FCEvents.loaded.rawValue, info: ["flowgraph": self])
	}
	
	/// This method calls reset on each flow node in the graph.
	public func reset() {
		Events.use()?.raise(by: self, FlowComponent.FCEvents.resetting.rawValue, info: ["graph": self])
		flowNodes.forEach { $0.reset() }
		Events.use()?.raise(by: self, FlowComponent.FCEvents.reset.rawValue, info: ["graph": self])
	}
	
	public func flow() {
		Events.use()?.raise(by: self, FlowComponent.FCEvents.flowing.rawValue, info: ["graph": self])
		flowNodes.forEach { $0.flow() }
		Events.use()?.raise(by: self, FlowComponent.FCEvents.flowed.rawValue, info: ["graph": self])
		if let _ = flowNodes.first(where: { $0.state == .failed }) {
			self.status = .failed
			Events.use()?.raise(by: self, FlowComponent.FCEvents.stateChanged.rawValue, info: ["graph": self])
			return
		}
		if let _ = flowNodes.first(where: { $0.state == .waiting }) {
			self.status = .waiting
			Events.use()?.raise(by: self, FlowComponent.FCEvents.stateChanged.rawValue, info: ["graph": self])
			return
		}
		self.status = .finished
		Events.use()?.raise(by: self, FlowComponent.FCEvents.stateChanged.rawValue, info: ["graph": self])
		Events.use()?.raise(by: self, FlowComponent.FCEvents.finishedFlowing.rawValue, info: ["graph": self])
	}
}

public struct FlowControlView: View {
	var flowGraph: Graph
	public var body: some View {
		VStack {
			HStack {
				Spacer()
				Button {
					flowGraph.flow()
				} label: {
					Label("Flow", systemImage: "hare.fill")
				}
			}
			Spacer()
		}
		
	}
}
public struct FlowGraphView: View {
	@State var scale: CGFloat = 1.0
	@State var showingNodes = false
	@State var flowNodeNames: [NSString] = []
	@ObservedObject public var graph: Graph
	var flowNodes: [FlowNode] = []
	var flowPipes: [FlowPipe] = []
	
	public init(graph: Graph) {
		self.graph = graph
		flowNodes = graph.flowNodes.map({ fl in
			fl as! FlowNode
		})
		flowPipes = graph.flowPipes
		print("Nodes: \(flowNodes.count) \nPipes: \(flowPipes.count)")
	}

	public var body: some View {
		VStack(alignment: .leading) {
			ZStack(alignment: .leading) {
				ForEach(flowNodes, id: \.self) { fn in
					FlowNodeView(flowNode: fn)
				}
				FlowControlView(flowGraph: graph)
			}
			.frame(width: graph.graphSize.width, height: graph.graphSize.height)
			.background(FlowPipesView(graph: graph))
			.background(
					HStack { Color.gray.opacity(0.1) }
					.frame(width: graph.graphSize.width, height: graph.graphSize.height)
				)
				Spacer()
		}
		.frame(width: graph.graphSize.width, height: graph.graphSize.height)
		.onAppear() { flowNodeNames = FlowNodeRegistry.shared.flowNodeClasses }
		.scaleEffect(scale)
		.contextMenu {
			Menu("Nodes") {
				ForEach(flowNodeNames, id: \.self) { className in
					Button("\(className)" ) {
						print("Tapped \(className)")
					}
				}
			}
			Button {
				showingNodes = false
			} label: {
				Label("Close", systemImage: "box")
					.onHover { over in
						showingNodes = over
					}
				}
				.popover(isPresented: $showingNodes) {
					FlowFinderView()
				}
				.transition(.move(edge: .leading))
				.animation(.spring(), value: 2.0)
			}
		
//			.frame(maxWidth: .infinity, maxHeight: .infinity)/
//			.offset(x: graph.drawOffset.x, y: graph.drawOffset.y)
			.gesture(
				DragGesture(minimumDistance: 10, coordinateSpace: .global).onChanged({ ges in
					if graph.dragStarted == nil {
						graph.dragStarted = graph.drawOffset
					}
					else {
						graph.drawOffset.x = graph.dragStarted.x + ges.translation.width
						graph.drawOffset.y = graph.dragStarted.y + ges.translation.height
					}
				})
				.onEnded({ ges in
					graph.dragStarted = nil
				})
			)
			.onTapGesture {
				if graph.dragSource != nil {
					graph.dragSource = nil
				}
			}
		
		
//		}.background(LinearGradient(colors: [Color( #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)),Color( #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)), Color( #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1))], startPoint: .topLeading, endPoint: .bottomTrailing))
		
		
//		.tiledBackground(
//			with: Image("TiledBackground"),
//			capInsets: EdgeInsets(all: 23)
//		)
	}
}


public struct FlowPipesView: View {
	@ObservedObject var graph: Graph
	public var body: some View {
		drawPipes()
	}
	
	func drawPipes() -> some View {
		print("Drawing \(graph.flowPipes.count) pipe(s) from: \(graph.flowPipes.first?.source?.position ?? .zero) to: \(graph.flowPipes.first?.destination?.position ?? .zero).")
		return ZStack(alignment: .topLeading) {
			ForEach(graph.flowPipes, id: \.self) { fp in
				FlowPipeView(pipe: fp)
			}
		}
	}
}
