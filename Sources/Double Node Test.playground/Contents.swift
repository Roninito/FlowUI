import Cocoa
import FlowUI
import PlaygroundSupport
import SwiftUI

print("\(FlowNodeRegistry.shared.flowNodeClasses)")
//FlowNodeRegistry.shared
let graph = Graph()
let node = StringFlowNode(graph: graph, at: CGPoint(x: 200, y: 200))
node.stringValue = "New node"
graph.flowNodes.append(node)

let node2 = StringFlowNode(graph: graph, at: CGPoint(x: 450, y: 200))
node2.stringValue = "New node"
graph.flowNodes.append(node2)

let node3 = LogNode(graph: graph, at: CGPoint(x: 450, y: 400))
node3.prefix = "New Log: "
graph.flowNodes.append(node3)

let fgv = FlowGraphView(graph: graph)
let hostingView = NSHostingView(rootView: ScrollView([.vertical, .horizontal]) { fgv })
hostingView.autoresizesSubviews = true
//hostingView.setFrameSize(NSSize(width: 600, height: 600))
PlaygroundPage.current.setLiveView(hostingView)
PlaygroundPage.current.needsIndefiniteExecution = true

