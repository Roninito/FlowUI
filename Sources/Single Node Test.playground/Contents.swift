import Cocoa
import FlowUI
import PlaygroundSupport
import SwiftUI

print("\(FlowNodeRegistry.shared.flowNodeClasses)")

let graph = Graph()
let node = StringFlowNode(graph: graph, at: CGPoint(x: 200, y: 200))
node.stringValue = "New node"
graph.flowNodes.append(node)

let fgv = FlowGraphView(graph: graph)
let hostingView = NSHostingView(rootView: fgv)
hostingView.setFrameSize(NSSize(width: 600, height: 600))

PlaygroundPage.current.setLiveView(hostingView)

