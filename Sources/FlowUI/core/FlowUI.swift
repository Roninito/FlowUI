import RoninUtilities
import SwiftUI
import Combine


public struct FlowUI {
    public private(set) var text = "Hello, World!"
    public init() {}
}


public typealias FlowProcessingAction = (Flowable) -> ()


public enum FlowState: Int {
	case resting, waiting, processing, finished, failed
}


public enum FlowSocketType {
	case inlet, outlet
}


public enum FlowDataType {
	case number, string, texture, vector, scnnode, sknode, prefab, archtype, color, cgfloat, float, double
	
	public func asColor() -> Color {
		switch(self) {
			
		case .number:
			return .orange
		case .string:
			return .pink
		case .texture:
			return .green
		case .vector:
			return .purple
		case .scnnode:
			return .yellow
		case .sknode:
			return .gray
		case .prefab:
			return .brown
		case .archtype:
			return .blue
		case .color:
			return .pink
		case .cgfloat:
			return .orange
		case .float:
			return .orange
		case .double:
			return .orange
		}
	}
}

public enum FlowNodeType {
	case reference, value, generator, controller, actuator, sensor, event, service
}


public protocol Flowable: AnyObject {
	var owner: FlowGraphable { get set }
	var state: FlowState { get set }
	var inlets:[Inlet] { get set }
	var outlets: [Outlet] { get set }
	var position: CGPoint { get set }
	var reportedWidth: CGFloat { get set }
	var reportedHeight: CGFloat { get set }
	func load()
	func flow()
	func reset()
	func activity(flowNode: Flowable)
	func controls() -> AnyView
	func process(_ owner: Flowable)
	func flowView() -> AnyView
}


public protocol FlowGraphable {
	var flowQueue: DispatchQueue! { get set }
	var flowNodes: Array<Flowable> { get set }
	var flowPipes: [FlowPipe] { get set }
	var subscriptions: Set<AnyCancellable> { get set }
	var dragSource: FlowSocket! { get set }
}


public protocol FlowConnectable: NSObject {
	var source: FlowSocket? { get set }
	var destination: FlowSocket? { get set }
	func flow()
}


public protocol FlowSocket {
	var owner: Flowable { get set }
	var pipes: [FlowConnectable] { get set }
	var socketType: FlowSocketType { get set }
	var dataType: FlowDataType { get set }
	var value: Any? { get set }
	var position: CGPoint { get set }
}
