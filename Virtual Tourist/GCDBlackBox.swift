//
//  GCDBlackBox.swift
//  Virtual Tourist
//
//  Created by Paul ReFalo on 12/31/16.
//  Copyright © 2016 QSS. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
