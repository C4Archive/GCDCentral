//
//  AppDelegate.swift
//  GCDCentral
//
//  Created by travis on 2015-07-09.
//  Copyright (c) 2015 C4. All rights reserved.
//

import Cocoa

func Dlog(message: String, function: String = __FUNCTION__) {
    #if DEBUG
        println("\(function): \(message)")
    #endif
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate {
    var netService : NSNetService?
    var asyncSocket : GCDAsyncSocket?
    var connectedSockets = [GCDAsyncSocket]()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        asyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())

        var error : NSError?
        if asyncSocket?.acceptOnPort(0, error: &error) == true {
            if let port : UInt16 = asyncSocket?.localPort {
                netService = NSNetService(domain: "local.", type: "_m-o._tcp.", name: "m-o-centralService", port: Int32(port))
                netService?.delegate = self
                netService?.publish()
            }
        } else {
            Dlog("Error in acceptOnPort:error: -> \(error)")
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("relayMouseEvent:"), name: "down", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("relayMouseEvent:"), name: "dragged", object: nil)
    }

    func relayMouseEvent(notification: NSNotification) {
        var location = ""
        if let info = notification.userInfo as? Dictionary<String,NSEvent> {
            if let event = info["event"] {
                location += "\(event.locationInWindow)"
            }
            else {
                println("no value for key")
            }
        }
        else {
            println("wrong userInfo type")
        }

        let message = "\(notification.name):\(location)"
        writeToSockets(connectedSockets, message: message)
    }

    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        println("shouldTerminate")
        for s in connectedSockets {
            s.disconnect()
        }
        return .TerminateNow
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        for s in connectedSockets {
            s.disconnect()
        }
    }

    func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        Dlog("Accepted new socket from \(newSocket.connectedHost):\(newSocket.connectedPort)")
        connectedSockets.append(newSocket)
        writeTo(newSocket, message: "handshake-from-central")
    }

    func writeTo(sock: GCDAsyncSocket, message: String) {
        let data = NSMutableData(data: message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        data.appendData(GCDAsyncSocket.CRLFData())

        sock.writeData(data, withTimeout: -1, tag: 0)
        sock.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 0)
    }

    func writeToSockets(sockets: [GCDAsyncSocket], message: String) {
        let data = NSMutableData(data: message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        data.appendData(GCDAsyncSocket.CRLFData())

        for sock in sockets {
            sock.writeData(data, withTimeout: -1, tag: 0)
            sock.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 0)
        }
    }

    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        if let s = sock,
            let index = find(connectedSockets,s) {
                connectedSockets.removeAtIndex(index)
                println("removed a socket \(println(connectedSockets.count))")
        }
    }

    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        println("didRead")
        let s = NSString(data: data, encoding: NSUTF8StringEncoding)
    }

    func socket(sock: GCDAsyncSocket!, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        println("didWritePartialDataOfLength")
    }

    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        println("should read")
        sock.readDataWithTimeout(-1, tag: 0)
    }

    func socket(sock: GCDAsyncSocket!, shouldTimeoutWriteWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        println("shouldTimeoutWriteWithTag")
        return 5.0
    }
}

