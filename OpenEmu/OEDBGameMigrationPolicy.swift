/*
 Copyright (c) 2016, OpenEmu Team

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the OpenEmu Team nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Cocoa

class OEDBGameMigrationPolicy: NSEntityMigrationPolicy
{
    override func createDestinationInstancesForSourceInstance(sInstance: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws
    {
        assert(manager.sourceModel.versionIdentifiers.count == 1, "Found a source model with various versionIdentifiers!");
        let version = manager.sourceModel.versionIdentifiers.first!;
        if version == "1.3" {
            for attributeMapping in mapping.attributeMappings! {
                let roms = sInstance.valueForKey("roms") as! Set<NSManagedObject>

                switch attributeMapping.name! {
                case "playCount":
                    let totalPlayCount = roms.map({
                        $0.valueForKey("playCount")?.integerValue ?? 0
                    }).reduce(0, combine: +)

                    attributeMapping.valueExpression = NSExpression(forConstantValue: totalPlayCount)

                case "playTime":
                    let totalPlayTime = roms.map({
                        $0.valueForKey("playTime")?.doubleValue ?? 0.0
                    }).reduce(0, combine: +)

                    attributeMapping.valueExpression = NSExpression(forConstantValue: totalPlayTime)

                case "lastPlayed":
                    let lastPlayed = roms.flatMap({
                        $0.valueForKey("lastPlayed") as? NSDate
                    }).maxElement({ (d1, d2) -> Bool in
                        return d1.compare(d2) == NSComparisonResult.OrderedDescending
                    })
                    attributeMapping.valueExpression = NSExpression(forConstantValue: lastPlayed)

                default: break
                }
            }
        }

        try super.createDestinationInstancesForSourceInstance(sInstance, entityMapping: mapping, manager: manager)
    }
}