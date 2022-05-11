//
//  File.swift
//  
//
//  Created by leerie simpson on 4/30/22.
//

import Foundation
import SwiftUI


public class FlowPipe: NSObject, NSSecureCoding, FlowConnectable, ObservableObject {
	public static var supportsSecureCoding: Bool = true
	public var source: FlowSocket?
	public var destination: FlowSocket?
	@Published public var isSelected = false
	
	public func encode(with coder: NSCoder) {
		coder.encode(source, forKey: "source")
		coder.encode(destination, forKey: "destination")
	}
	
	public required init?(coder: NSCoder) {
		super.init()
		source = coder.decodeObject(of: [Outlet.self], forKey: "source") as? FlowSocket
		destination = coder.decodeObject(of: [Inlet.self], forKey: "destination") as? FlowSocket
	}

	public func flow() {
		destination?.value = source?.value
	}
	
	public init(source: FlowSocket, destination: FlowSocket) {
		self.source = source
		self.destination = destination
	}
	
	public func destroy() {
		source?.owner.owner.flowPipes.removeAll(where: { pipe in
			pipe == self
		})
		source?.pipes.removeAll(where: { fc in
			(fc as? FlowPipe) == self
		})
		destination?.pipes.removeAll(where: { fc in
			(fc as? FlowPipe) == self
		})
		
		(source?.owner.owner as? Graph)?.objectWillChange.send()
		(source as? Inlet)?.objectWillChange.send()
		(destination as? Outlet)?.objectWillChange.send()
	}
}


public struct FlowPipeView: View {
	@ObservedObject var pipe: FlowPipe
	@ObservedObject var inlet: Inlet
	@ObservedObject var outlet: Outlet
//	@State var isSelected = false
	
	public init(pipe: FlowPipe) {
		self.pipe = pipe
		self.inlet = pipe.destination as! Inlet
		self.outlet = pipe.source as! Outlet
	}
	
	public var body: some View {
		Canvas { context, size in
			context.stroke(
				Path { p in
					p.move(to: outlet.position)
					p.addLine(to: CGPoint(x: outlet.position.x + 10, y: outlet.position.y))
					p.addLine(to: CGPoint(x: inlet.position.x - 10, y: inlet.position.y))
					p.addLine(to: inlet.position)
				}, with: .foreground, style: .init(lineWidth: 1, lineCap: CGLineCap.square, lineJoin: .bevel)
			)
		}
		.shadow(color: (pipe.source as! Outlet).dataType.asColor().opacity(0.4), radius: 5, x: 2, y: 2)
		.foregroundColor(pipe.isSelected ? Color("flowPipeSelectedColor"): (pipe.source as! Outlet).dataType.asColor())
		.onTapGesture(count: 2) {
			pipe.isSelected.toggle()
		}
		.overlay(
			ZStack(alignment: .topLeading) {
				if pipe.isSelected == true {
					Button {
						(pipe.source?.owner.owner as? Graph)?.objectWillChange.send()
						pipe.destroy()
					} label: {
						Circle().frame(width: 15, height: 15)
					}
					.frame(width: 15, height: 15)
					.foregroundColor(Color("flowNodePipeHandleColor"))
					.position(inlet.position)
					.buttonStyle(PlainButtonStyle())
					.keyboardShortcut(.delete, modifiers: [.command])
					.zIndex(100)
					
					Button {
						(pipe.source?.owner.owner as? Graph)?.objectWillChange.send()
						pipe.destroy()
						
					} label: {
						Circle().frame(width: 15, height: 15)
					}
					.frame(width: 15, height: 15)
					.foregroundColor(Color("flowNodePipeHandleColor"))
					.position(outlet.position)
					.buttonStyle(PlainButtonStyle())
					.keyboardShortcut(.delete, modifiers: [.command])
					.zIndex(100)
				}
			}
		)
	}
}
