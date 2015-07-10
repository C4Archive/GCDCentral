//
//  AppDelegate.swift
//  GCDCentral
//
//  Created by travis on 2015-07-09.
//  Copyright (c) 2015 C4. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate {
    var netService : NSNetService?
    var asyncSocket : GCDAsyncSocket?
    var connectedSockets = [GCDAsyncSocket]()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        asyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())

        var err : NSError?

        if asyncSocket?.acceptOnPort(0, error: &err) == true {
            if let port : UInt16 = asyncSocket?.localPort {
                netService = NSNetService(domain: "local.", type: "_m-o._tcp.", name: "m-o-centralService", port: Int32(port))

                netService?.delegate = self
                netService?.publish()
            }
        } else {
            println("Error in acceptOnPort:error: -> \(err)")
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("test:"), name: "down", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("test:"), name: "dragged", object: nil)
    }

    func test(notification: NSNotification) {

        var location = "-"
        if let info = notification.userInfo as? Dictionary<String,NSEvent> {
            // Check if value present before using it
            if let event = info["event"] {
                location = "-\(event.locationInWindow)"
                println(location)
            }
            else {
                print("no value for key\n")
            }
        }
        else {
            print("wrong userInfo type")
        }


        let test = "\(notification.name)-\(location)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let md = NSMutableData()

        md.appendData(test!)
        md.appendData(GCDAsyncSocket.CRLFData())

        for socket in connectedSockets {
            socket.writeData(md, withTimeout: -1, tag: 0)
            socket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 0)
        }
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
        println("Accepted new socket from \(newSocket.connectedHost):\(newSocket.connectedPort)")

        let handshake = "handshake-from-central".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let md = NSMutableData()
        md.appendData(handshake!)
        md.appendData(GCDAsyncSocket.CRLFData())
        newSocket.writeData(md, withTimeout: -1, tag: 0)
        newSocket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 0)
        connectedSockets.append(newSocket)
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
        println(s)
    }

    func socket(sock: GCDAsyncSocket!, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        println("didWritePartialDataOfLength")
    }

    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        println("tag \(tag)")
        println("should read")
        sock.readDataWithTimeout(-1, tag: 0)
    }

    func socket(sock: GCDAsyncSocket!, shouldTimeoutWriteWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        println("shouldTimeoutWriteWithTag")
        return 5.0
    }
}

