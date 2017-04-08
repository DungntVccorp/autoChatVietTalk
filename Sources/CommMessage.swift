//
//  CommMessage.swift
//  vt2
//
//  Created by Nguyen Dung on 10/19/16.
//  Copyright © 2016 Vivas. All rights reserved.
//
/**
 Cấu trúc header của message như sau
 0xEE 0xEE (2)|Size (3)|Type (2)|Flag(1)|Message Id (8)|Data (Protobuf message)
 */
import Foundation

public extension Data{
    
    //MARK: - 🆑 Custom Method
    
    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
    
    
    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.pointee }
    }
    
    var binary : [UInt8] {
        return self.withUnsafeBytes {
            Array(UnsafeBufferPointer<UInt8>(start: $0, count: self.count/MemoryLayout<UInt8>.size))
        }
    }
    
    var getInt32 : Int32? {
        guard self.count <= MemoryLayout<Int32>.size else {
            return nil
        }
        var binary = self.binary
        if(binary.count < MemoryLayout<Int32>.size){
            let numberInsert = MemoryLayout<Int32>.size - binary.count
            for _ in 0..<numberInsert{
                binary.insert(0, at: 0)
            }
        }
        let bigEndianValue = binary.withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: Int32.self, capacity: 1) { $0 })
            }.pointee
        return Int32(bigEndian: bigEndianValue)
    }
    var getUInt32 : UInt32? {
        guard self.count <= MemoryLayout<UInt32>.size else {
            return nil
        }
        var binary = self.binary
        if(binary.count < MemoryLayout<UInt32>.size){
            let numberInsert = MemoryLayout<UInt32>.size - binary.count
            for _ in 0..<numberInsert{
                binary.insert(0, at: 0)
            }
        }
        let bigEndianValue = binary.withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
            }.pointee
        return UInt32(bigEndian: bigEndianValue)
    }
    var getInt64 : Int64? {
        guard self.count <= MemoryLayout<Int64>.size else {
            return nil
        }
        var binary = self.binary
        if(binary.count < MemoryLayout<Int64>.size){
            let numberInsert = MemoryLayout<Int64>.size - binary.count
            for _ in 0..<numberInsert{
                binary.insert(0, at: 0)
            }
        }
        let bigEndianValue = binary.withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: Int64.self, capacity: 1) { $0 })
            }.pointee
        return Int64(bigEndian: bigEndianValue)
    }
    var getUInt64 : UInt64? {
        guard self.count <= MemoryLayout<UInt64>.size else {
            return nil
        }
        var binary = self.binary
        if(binary.count < MemoryLayout<UInt64>.size){
            let numberInsert = MemoryLayout<UInt64>.size - binary.count
            for _ in 0..<numberInsert{
                binary.insert(0, at: 0)
            }
        }
        let bigEndianValue = binary.withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: UInt64.self, capacity: 1) { $0 })
            }.pointee
        return UInt64(bigEndian: bigEndianValue)
    }
    var getInt : Int? {
        guard self.count <= MemoryLayout<Int>.size else {
            return nil
        }
        var binary = self.binary
        if(binary.count < MemoryLayout<Int>.size){
            let numberInsert = MemoryLayout<Int>.size - binary.count
            for _ in 0..<numberInsert{
                binary.insert(0, at: 0)
            }
        }
        let bigEndianValue = binary.withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: Int.self, capacity: 1) { $0 })
            }.pointee
        return Int(bigEndian: bigEndianValue)
    }
    
}


public class CommMessage {
    
    public private(set) var msg_size : Int? = 8
    public private(set) var msg_type : Int32?
    public private(set) var msg_rID  : UInt64?
    public private(set) var msg_data : Data?
    
    
    public func toByteArray<T>(_ value: T) -> [UInt8] {
        let totalBytes = MemoryLayout<T>.size
        var value = value
        return withUnsafePointer(to: &value) { valuePtr in
            return valuePtr.withMemoryRebound(to: UInt8.self, capacity: totalBytes) { reboundPtr in
                return Array(UnsafeBufferPointer(start: reboundPtr, count: totalBytes))
            }
        }
    }
    
    init(type : Int32,rID : UInt64?,data : Data) {
        self.msg_data = data
        self.msg_rID = rID
        self.msg_type = type
        if(rID != nil){
            self.msg_size = self.msg_size! + 8
        }
        self.msg_size = (self.msg_size ?? 0) + data.count
    }
    init?(withProtoData rawData : Data) {
                
        guard rawData.count > 0x8 else {
            return nil
        }
        guard rawData[0] == 0xee else {
            return nil
        }
        guard rawData[1] == 0xee else {
            return nil
        }
        
        if let _size = rawData.subdata(in: 0x2..<0x5).getInt{
            if(_size > rawData.count){
                return nil
            }
            self.msg_size = _size
        }else{
            return nil
        }
        if let _type = rawData.subdata(in: 0x5..<0x7).getInt32{
            self.msg_type = _type
        }else{
            return nil
        }
        if let _flag = rawData.subdata(in: 0x7..<0x8).getInt{
            if(_flag == 0){ // khong co id
                self.msg_data = rawData.subdata(in: 0x8..<self.msg_size!)
            }
            else{
                if(self.msg_type == 0){
                    if let _type = rawData.subdata(in: 0x8..<0xA).getInt32{
                        self.msg_type = _type
                    }
                    if let _rID = rawData.subdata(in: 0xA..<0x10).getUInt64{
                        self.msg_rID = _rID
                        self.msg_data = rawData.subdata(in: 0x10..<self.msg_size!)
                        
                    }else{
                        return nil
                    }
                }
                else{
                    if let _rID = rawData.subdata(in: 0x8..<0x10).getUInt64{
                        self.msg_rID = _rID
                        self.msg_data = rawData.subdata(in: 0x10..<self.msg_size!)
                        
                    }else{
                        return nil
                    }
                }
                
            }
        }else{
            return nil
        }    
    }
    func get_data() -> Data?{
        guard msg_data != nil && msg_type != nil && msg_size != nil else {
            return nil
        }
        var rawData = Data()
        rawData.append([0xEE,0xEE], count: 2) // header
        rawData.append([UInt8((self.msg_size! >> 16) & 0xFF),UInt8((self.msg_size! >> 8) & 0xFF),UInt8(self.msg_size! & 0xFF)], count: 3) // message size
        rawData.append([UInt8((self.msg_type! >> 8) & 0xFF),UInt8(self.msg_type! & 0xFF)], count: 2) // message type
        if(self.msg_rID != nil){ // có id
            rawData.append([0x2], count: 1)
            rawData.append([UInt8((self.msg_type! >> 8) & 0xFF),
                            UInt8(self.msg_type! & 0xFF)], count: 2) // 2byte custom id
            rawData.append([UInt8((self.msg_rID! >> 40) & 0xFF),
                            UInt8((self.msg_rID! >> 32) & 0xFF),
                            UInt8((self.msg_rID! >> 24) & 0xFF),
                            UInt8((self.msg_rID! >> 16) & 0xFF),
                            UInt8((self.msg_rID! >> 8) & 0xFF),
                            UInt8(self.msg_rID! & 0xFF)], count: 6) // message ID
        }
        else{
            rawData.append([0x0], count: 1)
        }
        rawData.append(self.msg_data!) // proto data
        return rawData
    }
    deinit {
        msg_size = 0
        msg_type = 0
        msg_rID = 0
        msg_data = nil
    }
}

extension Data{
    var uuid_encode : Data{
        guard self.count == 16 else {
            return Data()
        }
        let _keyStr : Array<Character> = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","-","_","="]
        let asUInt8Array = String(_keyStr).utf8.map{ UInt8($0) }
        let input = self.binary
        let c = self.count * 4
        var output = [UInt8](repeating: 0, count: c / 3 + c % 3)
        var i : Int = 0
        var j : Int = 0
        var chr1 : UInt8 = 0
        var chr2 : UInt8 = 0
        var chr3 : UInt8 = 0
        var enc1 : UInt8 = 0
        var enc2 : UInt8 = 0
        var enc3 : UInt8 = 0
        var enc4 : UInt8 = 0
        while i < 16 {
            chr1 = input[i]
            i += 1
            enc1 = chr1 >> 2
            output[j] = asUInt8Array[Int(enc1)]
            j += 1
            if (i < 16)
            {
                chr2 = input[i]
                i += 1
                enc2 = ((chr1 & 3) << 4) | (chr2 >> 4)
                output[j] = asUInt8Array[Int(enc2)]
                j += 1
            }else{
                output[j] = asUInt8Array[Int((chr1 & 3)<<4)]
                j += 1
                break
            }
            
            if (i < 16){
                chr3 = input[i]
                i += 1
                enc3 = ((chr2 & 15) << 2) | (chr3 >> 6)
                output[j] = asUInt8Array[Int(enc3)]
                j += 1
            }
            else{
                output[j] = asUInt8Array[Int((chr2 & 15)<<2)]
                j += 1
                break
            }
            
            enc4 = chr3 & 63;
            output[j] = asUInt8Array[Int(enc4)]
            j += 1
        }
        return Data(bytes: output, count: j)
    }
}
extension Data{
    init(randomDatabyte length : Int) {
        var output = [UInt8](repeating: 0, count: length)
        for i in 0..<length{
            output[i] = UInt8(arc4random_uniform(254))
        }
        self.init(bytes: output)
    }
    
}





