//
//  TaskViewController.swift
//  TaskCaptureSample
//
//  Created by Akira Matsuda on 2022/08/17.
//

import Combine
import LocalConsole
import UIKit

func longTask() async {
    let seconds = 4
    let duration = UInt64(seconds * 1000000000)
    do {
        try await Task.sleep(nanoseconds: duration)
    }
    catch {
        log("Task error: \(error.localizedDescription)")
    }
    guard !Task.isCancelled else {
        log("Task canceled")
        return
    }
}

func log(_ items: Any) {
    print(items)
    Task.detached {
        await MainActor.run {
            LCManager.shared.print(items)
        }
    }
}

func cleanup() {
    if Task.isCancelled {
        TaskCaptureSample.log("defer: Task canceled")
    }
    else {
        TaskCaptureSample.log("Task defer")
    }
}

// MARK: - TaskViewController

class TaskViewController: UIViewController {
    // MARK: Lifecycle

    deinit {
        TaskCaptureSample.log("deinit")
    }

    // MARK: Internal

    enum State: CustomStringConvertible {
        case running
        case finished

        // MARK: Internal

        var description: String {
            switch self {
            case .running:
                return "running"
            case .finished:
                return "finished"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        $isRunning.sink { [unowned self] running in
            if running {
                self.activityIndicator.startAnimating()
            }
            else {
                self.activityIndicator.stopAnimating()
            }
            buttons.forEach { button in
                button.isEnabled = !running
            }
        }.store(in: &cancellable)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        longTask?.cancel()
    }

    @IBAction func runLongTask() {
        TaskCaptureSample.log(#function)
        Task {
            defer { cleanup() }
            updateState(.running)
            await TaskCaptureSample.longTask()
            updateState(.finished)
        }
    }

    @IBAction func runLongWeakTask() {
        TaskCaptureSample.log(#function)
        Task { [weak self] in
            defer { cleanup() }
            self?.updateState(.running)
            await TaskCaptureSample.longTask()
            self?.updateState(.finished)
        }
    }

    @IBAction func runLongTaskWithCancel() {
        TaskCaptureSample.log(#function)
        longTask = Task {
            defer { cleanup() }
            updateState(.running)
            await TaskCaptureSample.longTask()
            updateState(.finished)
        }
    }

    @IBAction func runLongDetachedTask() {
        TaskCaptureSample.log(#function)
        Task.detached {
            defer { cleanup() }
            await self.updateState(.running)
            await TaskCaptureSample.longTask()
            await self.updateState(.finished)
        }
    }

    @IBAction func runLongDetachedWeakTask() {
        TaskCaptureSample.log(#function)
        Task.detached { [weak self] in
            defer { cleanup() }
            await self?.updateState(.running)
            await TaskCaptureSample.longTask()
            await self?.updateState(.finished)
        }
    }

    @MainActor
    func updateState(_ state: State) {
        label.text = state.description
        if state == .running {
            isRunning = true
        }
        else {
            isRunning = false
        }
        TaskCaptureSample.log(state.description)
    }

    // MARK: Private

    @IBOutlet private var buttons: [UIButton]!
    @IBOutlet private var label: UILabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @Published private var isRunning = false
    private var cancellable = Set<AnyCancellable>()
    private var longTask: Task<Void, Never>?
}
