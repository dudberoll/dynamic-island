import Darwin
import Foundation

public final class KanbanFileWatcher {
    private let sourceURL: URL
    private let debounceNanoseconds: UInt64
    private let onChange: () -> Void
    private let queue = DispatchQueue(label: "dynamic-island.kanban-file-watcher")

    private var directoryDescriptor: CInt = -1
    private var fileDescriptor: CInt = -1
    private var directorySource: DispatchSourceFileSystemObject?
    private var fileSource: DispatchSourceFileSystemObject?
    private var debounceTask: DispatchWorkItem?

    public init(
        sourceURL: URL,
        debounceNanoseconds: UInt64 = 350_000_000,
        onChange: @escaping () -> Void
    ) {
        self.sourceURL = sourceURL
        self.debounceNanoseconds = debounceNanoseconds
        self.onChange = onChange
    }

    deinit {
        stop()
    }

    public func start() {
        stop()
        queue.async { [weak self] in
            self?.startDirectoryWatcher()
            self?.startFileWatcher()
        }
    }

    public func stop() {
        debounceTask?.cancel()
        debounceTask = nil

        directorySource?.cancel()
        directorySource = nil
        fileSource?.cancel()
        fileSource = nil
    }

    private func startDirectoryWatcher() {
        let directoryPath = sourceURL.deletingLastPathComponent().path
        let descriptor = open(directoryPath, O_EVTONLY)
        directoryDescriptor = descriptor

        guard descriptor >= 0 else {
            scheduleDebouncedChange()
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete, .attrib],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            self?.restartFileWatcher()
            self?.scheduleDebouncedChange()
        }

        source.setCancelHandler { [weak self] in
            close(descriptor)

            if self?.directoryDescriptor == descriptor {
                self?.directoryDescriptor = -1
            }
        }

        directorySource = source
        source.resume()
    }

    private func startFileWatcher() {
        let descriptor = open(sourceURL.path, O_EVTONLY)
        fileDescriptor = descriptor

        guard descriptor >= 0 else {
            scheduleDebouncedChange()
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .rename, .delete, .attrib],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            self?.scheduleDebouncedChange()
        }

        source.setCancelHandler { [weak self] in
            close(descriptor)

            if self?.fileDescriptor == descriptor {
                self?.fileDescriptor = -1
            }
        }

        fileSource = source
        source.resume()
    }

    private func restartFileWatcher() {
        fileSource?.cancel()
        fileSource = nil
        startFileWatcher()
    }

    private func scheduleDebouncedChange() {
        debounceTask?.cancel()

        let task = DispatchWorkItem { [weak self] in
            self?.onChange()
        }

        debounceTask = task
        queue.asyncAfter(deadline: .now() + .nanoseconds(Int(debounceNanoseconds)), execute: task)
    }
}
