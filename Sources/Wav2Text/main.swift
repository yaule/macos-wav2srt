import Speech
import Foundation
import AVFoundation

// 添加权限检查
func checkPermissions() {
    print("检查权限状态...")
    SFSpeechRecognizer.requestAuthorization { authStatus in
        switch authStatus {
        case .authorized:
            print("语音识别权限：已授权")
        case .denied:
            print("语音识别权限：已拒绝")
        case .restricted:
            print("语音识别权限：受限")
        case .notDetermined:
            print("语音识别权限：未确定")
        @unknown default:
            print("语音识别权限：未知状态")
        }
    }
}

// 检查音频文件的持续时间
func checkAudioFileDuration(filePath: String) -> Bool {
    let audioURL = URL(fileURLWithPath: filePath)
    do {
        let audioAsset = AVURLAsset(url: audioURL)
        let duration = CMTimeGetSeconds(audioAsset.duration)
        print("音频文件持续时间: \(duration) 秒")
        return duration > 0
    } catch {
        print("无法加载音频文件: \(error.localizedDescription)")
        return false
    }
}

// 格式化时间戳为 SRT 格式
func formatTimeStamp(_ seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = Int(seconds) / 60 % 60
    let secs = Int(seconds) % 60
    let milliseconds = Int((seconds - Double(Int(seconds))) * 1000)
    
    return String(format: "%02d:%02d:%02d,%03d", hours, minutes, secs, milliseconds)
}

// 保存转录结果为 SRT 文件
func saveTranscriptionToFile(transcriptions: [String]) {
    let filePath = "/tmp/transcription.srt"
    let fullText = transcriptions.joined(separator: "\n")
    do {
        try fullText.write(toFile: filePath, atomically: true, encoding: .utf8)
        print("字幕文件已保存到: \(filePath)")
    } catch {
        print("保存字幕文件时出错: \(error.localizedDescription)")
    }
}

// 转录音频文件
func transcribeAudio() {
    var subtitleIndex = 1
    var transcriptions: [String] = []
    
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN")) else {
        print("无法创建语音识别器")
        return
    }
    
    let audioFilePath = "/tmp/converted.wav"
    let audioURL = URL(fileURLWithPath: audioFilePath)
    
    if !FileManager.default.fileExists(atPath: audioFilePath) {
        print("音频文件不存在: \(audioFilePath)")
        return
    }
    
    if !checkAudioFileDuration(filePath: audioFilePath) {
        print("音频文件内容无效")
        return
    }
    
    if !recognizer.isAvailable {
        print("语音识别器当前不可用，请稍后重试")
        return
    }
    
    let request = SFSpeechURLRecognitionRequest(url: audioURL)
    request.requiresOnDeviceRecognition = false
    request.shouldReportPartialResults = false // 只输出最终结果
    
    print("开始语音识别...")
    recognizer.recognitionTask(with: request) { result, error in
        if let error = error {
            print("识别过程中发生错误: \(error.localizedDescription)")
            return
        }
        
        guard let result = result else {
            print("没有识别结果")
            return
        }
        
        if result.isFinal {
            print("转录完成!")
            for segment in result.bestTranscription.segments {
                let startTime = formatTimeStamp(segment.timestamp)
                let endTime = formatTimeStamp(segment.timestamp + segment.duration)
                let subtitleEntry = """
                \(subtitleIndex)
                \(startTime) --> \(endTime)
                \(segment.substring)
                
                """
                transcriptions.append(subtitleEntry)
                subtitleIndex += 1
            }
            saveTranscriptionToFile(transcriptions: transcriptions)
        }
    }
}

// 测试音频播放功能
func testAudioPlayback() {
    let audioFilePath = "/tmp/converted.wav"
    let audioURL = URL(fileURLWithPath: audioFilePath)

    do {
        let player = try AVAudioPlayer(contentsOf: audioURL) // 可能抛出错误
        player.prepareToPlay() // 不会抛出错误
        player.play() // 不会抛出错误
        print("音频播放测试成功")
    } catch {
        print("音频播放器初始化失败: \(error.localizedDescription)")
    }
}

// 主程序
print("程序启动...")
checkPermissions()

DispatchQueue.global(qos: .userInitiated).async {
    print("开始语音识别任务...")
    testAudioPlayback()
    transcribeAudio()
}

RunLoop.current.run() // 保持程序运行
