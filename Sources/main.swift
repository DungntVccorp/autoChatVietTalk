import Foundation
import Socket
import SwiftProtobuf
import KituraRequest



var host : String!
var port : UInt32!
var userId : Data!
var sessionId : Data!
var baseURL : String = "https://auth-vt2-beta.wala.vn/vt/r/"
var tel : String = "841234567888"
var pass : String = "a"
var id : UInt64 = 0
var deltalTime : Double!
var avata : String!
var userName : String!


var socket = try! Socket.create()
socket.readBufferSize = 4096
debugPrint("Auto Did Start")

func sendLoginTcp(){
    var rqLogin = Comm_Login.Request()
    rqLogin.sessionId = sessionId
    rqLogin.userId = userId
    let dataLogin = try! rqLogin.serializeProtobuf()
    
    let msg = CommMessage(type: Int32(Comm_Login.Extensions.Comm_Reply_id.protoFieldNumber), rID: id, data: dataLogin)
    
    if(socket.isConnected){
        let byteSend = try! socket.write(from: msg.get_data()!)
        debugPrint("Did Send \(byteSend) byte Login")
    }
    
}

func getListChat(){
    let rqChat = Comm_ListChats.Request()
    let dataListChat = try! rqChat.serializeProtobuf()
    id = id + 1
    let msg = CommMessage(type: Int32(Comm_ListChats.Extensions.Comm_Reply_id.protoFieldNumber), rID: id, data: dataListChat)
    if(socket.isConnected){
        let byteSend = try! socket.write(from: msg.get_data()!)
        debugPrint("Did Send \(byteSend) byte Get List Chat")
    }
}

func guiTinNhan(chatId : Data){
    
    var textMsg = Comm_TextMessage()
    textMsg.text = "test \(deltalTime!)"
    textMsg.hasEmoticon = false
    textMsg.hasLink = false
    let textMsgData = try!  textMsg.serializeProtobuf()
    
    var sender = Comm_Member()
    sender.avatar = avata
    sender.memberId = userId
    sender.name = userName
    sender.tel = tel
    sender.viettalkUser = true

    
    var message = Comm_Message()
    message.data = textMsgData
    message.time = UInt64(Date().addingTimeInterval(deltalTime).timeIntervalSince1970 * 1000)
    message.chatId = chatId
    message.messageId = Data(randomDatabyte: 16)
    message.sender = sender
    message.type = UInt32(Comm_Message.TypeEnum.text.rawValue)
    message.status = UInt32(Comm_Message.Status.msgSending.rawValue)
    message.smsout = UInt32(Comm_Message.Sms.none.rawValue)
    message.state = UInt32(Comm_Message.State.normal.rawValue)
    var pushmessage = Comm_SendMessage.Request()
    pushmessage.message = message
    let dataForPushMessage = try! pushmessage.serializeProtobuf()
    
    let msg = CommMessage(type: Int32(Comm_SendMessage.Extensions.Comm_Reply_id.protoFieldNumber), rID: id, data: dataForPushMessage)
    
    if(socket.isConnected){
        let byteSend = try! socket.write(from: msg.get_data()!)
        debugPrint("Did Send \(byteSend) byte MSG")
    }
}

func processReply(rep : CommMessage,reType : Int32,requestID : UInt64){
    if(Int32(Comm_Login.Extensions.Comm_Reply_id.protoFieldNumber) == reType){
        /// Đã login xong
        debugPrint("Login Success")
        if let rep = try? Comm_Reply(protobuf: rep.msg_data!, extensions: Comm_CommProfile_Extensions){
            if let repLogin = rep.getExtensionValue(ext: Comm_Login.Extensions.Comm_Reply_id){
                debugPrint(repLogin.profile.tel ?? "")
                deltalTime = (Date().timeIntervalSince1970 - Double(repLogin.serverTime! / 1000)) * -1
                avata = repLogin.profile.avatar ?? ""
                userName = repLogin.profile.name ?? ""
                getListChat()
            }
        }
        
    }else if(Int32(Comm_ListChats.Extensions.Comm_Reply_id.protoFieldNumber) == reType){
        debugPrint("Đã lấy về list chat")
        if let rep = try? Comm_Reply(protobuf: rep.msg_data!, extensions: Comm_CommChat_Extensions){
            if let repChat = rep.getExtensionValue(ext: Comm_ListChats.Extensions.Comm_Reply_id){
                debugPrint("Có \(repChat.chats.count) Cuộc hội thoại")
                for chat in repChat.chats{
                    if(chat.name == "889"){
                        guiTinNhan(chatId: chat.chatId)
                        
                    }
                }
                
            }
        }
    }else if(Int32(Comm_SendMessage.Extensions.Comm_Reply_id.protoFieldNumber) == reType){
        debugPrint("Gửi Tin Nhắn Thành Công")
        exit(0)
    }
}


func loginTcp(){
    do{
       try socket.connect(to: host, port: Int32(port))
        
        debugPrint("Connect to Host : \(socket.isConnected)")
        sendLoginTcp()
        var bufferData = Data(capacity: socket.readBufferSize)
        DispatchQueue.global().async {
            while true {
                do{
                    let bytesRead = try socket.read(into: &bufferData)
                    if(bytesRead != 0){
                        if(bufferData.count > 8){
                            var packageSize = bufferData.subdata(in: 0x2..<0x5).getInt
                            while (bufferData.count >= packageSize!){
                                if let msg = CommMessage(withProtoData: bufferData){
                                    debugPrint("parse \(msg.msg_size!) Bytes , Type : \(msg.msg_type ?? 0)")
                                    
                                    if(msg.msg_data != nil){
                                        processReply(rep: msg, reType: msg.msg_type ?? 0,requestID: msg.msg_rID ?? 0)
                                        
                                    }
                                    guard msg.msg_size! < bufferData.count else{
                                        bufferData.count = 0
                                        break
                                    }
                                    bufferData = bufferData.subdata(in: msg.msg_size!..<bufferData.count)
                                    guard bufferData.count > 8 else{
                                        bufferData.count = 0
                                        break
                                    }
                                    
                                    packageSize = bufferData.subdata(in: 0x2..<0x5).getInt ?? 0
                                }
                                else{
                                    break
                                }
                            }
                        }
                    }else{
                        print("chưa có msg")
                    }
                }catch{
                    print(error.localizedDescription)
                    break
                }
                
            }
        }
    }
        
    catch{
        
    }
    
}

var authen = Comm_Authenticate.Request()
authen.uid = tel
authen.password = pass
authen.platform = 1


let dataAuthen = try! authen.serializeProtobuf()

let urlAuthen  = baseURL + "\(Comm_Authenticate.Extensions.Comm_Reply_id.protoFieldNumber)"


var request = URLRequest(url: URL(string: urlAuthen)!)
request.httpBody = dataAuthen
request.httpMethod = "POST"
let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: OperationQueue.current)

let task = urlSession.dataTask(with: request) { (data, res, err) in
    if(data != nil){
        if let rep = try? Comm_Reply(protobuf: data!, extensions: Comm_CommProfile_Extensions){
            if let repAuthen = rep.getExtensionValue(ext: Comm_Authenticate.Extensions.Comm_Reply_id){
                userId = repAuthen.userId
                sessionId = repAuthen.sessionId
                host = repAuthen.host
                port = repAuthen.port
                let userIdDecode = userId.uuid_encode
                let userIdDecodeString = String(data: userIdDecode, encoding: String.Encoding.utf8)
                debugPrint("Host : \(host),Port : \(port), UserId : \(userIdDecodeString ?? "")")
                
                loginTcp()
            }
        }
    }
}
task.resume()

RunLoop.current.run()








