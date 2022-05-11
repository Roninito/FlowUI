//
//  File.swift
//  
//
//  Created by leerie simpson on 4/30/22.
//

import Foundation
import SwiftUI

public class LogNode: FlowNode {
	@Published public var prefix: String = ""
	
	
	public override init(graph: FlowGraphable, at position: CGPoint) {
		super.init(graph: graph, at: position)
		
		flowNodeName = "Log"
		let stringInlet = Inlet(flowNode: self)
		stringInlet.name = "log"
		inlets.append(stringInlet)
	}
	
	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public override func activity(flowNode: Flowable) {
		super.activity(flowNode: flowNode)
		if flowNode.inlets.first?.pipes.isEmpty == false {
			let stringValue = flowNode.inlets.first?.value as! String
			print(prefix + stringValue)
		}
	}
	
	
	public override func controls() -> AnyView {
		AnyView(VStack {
			LogControlsView(flowNode: self)
		})
	}
	
	struct LogControlsView: View {
		@ObservedObject var flowNode: LogNode
		var body: some View {
			TextField("", text: $flowNode.prefix)
		}
	}
}



public class StringFlowNode: FlowNode {
	
	@Published public var stringValue: String = "Empty"
	
	public override init(graph: FlowGraphable, at position: CGPoint) {
		super.init(graph: graph, at: position)
		
		flowNodeName = "String Reference"
		let stringOutlet = Outlet(flowNode: self)
		stringOutlet.name = "string"
		outlets.append(stringOutlet)
		
		let stringInlet = Inlet(flowNode: self)
		stringInlet.name = "string"
		inlets.append(stringInlet)
	}
	
	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public override func activity(flowNode: Flowable) {
		// if there is an inlet suggested value...
		if flowNode.inlets.first?.pipes.isEmpty == false {
			stringValue = flowNode.inlets.first?.value as! String
		}
		// set the outlet.
		flowNode.outlets.first?.value = stringValue
	}
	
	public override func controls() -> AnyView {
		AnyView(StringFlowNodeControlsView(stringFlowNode: self))
	}
}


public struct StringFlowNodeControlsView: View {
	@ObservedObject public  var flowNode: StringFlowNode
	@State var stringVal: String = ""
	public init(stringFlowNode: StringFlowNode) {
		self.flowNode = stringFlowNode
	}
	public var body: some View {
		HStack {
			Text("Value:").fontWeight(.bold)
			TextField("", text: $flowNode.stringValue)
		}
		.padding(2)
		.onAppear() {
			flowNode.$stringValue.sink { val in
				stringVal = val
				
			}.store(in: &flowNode.owner.subscriptions)
		}
	}
}
