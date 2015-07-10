//
//  ViewController.swift
//  GCDCentral
//
//  Created by travis on 2015-07-09.
//  Copyright (c) 2015 C4. All rights reserved.
//

import Cocoa

public class ViewController: NSViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    public override func mouseDown(theEvent: NSEvent) {
        NSNotificationCenter.defaultCenter().postNotificationName("down", object: self)
    }

    public override func mouseDragged(theEvent: NSEvent) {
        NSNotificationCenter.defaultCenter().postNotificationName("dragged", object: self)
    }
}

