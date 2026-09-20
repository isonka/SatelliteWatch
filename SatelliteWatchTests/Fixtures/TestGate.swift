import Foundation

actor TestGate {
    private var isOpen = false
    private var resumeWaiters: [CheckedContinuation<Void, Never>] = []
    private var entryCount = 0
    private var entryWaiters: [CheckedContinuation<Void, Never>] = []

    func enterAndWait() async {
        entryCount += 1
        let waiting = entryWaiters
        entryWaiters.removeAll()
        for waiter in waiting {
            waiter.resume()
        }

        guard !isOpen else { return }
        await withCheckedContinuation { continuation in
            resumeWaiters.append(continuation)
        }
    }

    func waitUntilEntered() async {
        guard entryCount == 0 else { return }
        await withCheckedContinuation { continuation in
            entryWaiters.append(continuation)
        }
    }

    func open() {
        isOpen = true
        let waiting = resumeWaiters
        resumeWaiters.removeAll()
        for waiter in waiting {
            waiter.resume()
        }
    }
}
