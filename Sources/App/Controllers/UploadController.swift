
import Vapor

final class UploadController {
    static func upload(_ req: Request) async throws -> HTTPStatus {
        struct Upload: Content { var file: File }
        let up = try req.content.decode(Upload.self)
        let dir = req.application.directory.workingDirectory + "Public/uploads/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let path = dir + up.file.filename
        try await req.fileio.writeFile(.init(data: up.file.data), at: path)
        return .created
    }
}
