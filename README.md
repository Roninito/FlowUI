# FlowUI

FlowUI is a SwiftUI based Visual Scripting/FlowGraph engine and editor. 

This package forms the core objects needed to get a simple flowgraph up and running. It contains a Graph containing Nodes and Pipes. Nodes for the actions of the graph and the pipes represent the data connections between the nodes. Each node has a set of sockets called inlets and outlets, and also a set of controls that allow configuration of the node. Each graph contains functionality allowing the user to manipulate nodes and pipes. 

The FlowNode Registry singleton provides global access to all nodes and their packages that conform to the Flowable protocol. This allows flow based packages to be built and included into projects as neccessary without having to include an infinite set of nodes in one package. This allows separation of concerns and openly declared the types of nodes being used in a particular project.

It was created to allow dynamic configuration of behavior for Astra Entities. 
