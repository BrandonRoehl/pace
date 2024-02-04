//
//  BatchScheduler.swift
//  Pace
//
//  Created by Brandon Roehl on 2/11/23.
//

import Foundation
import Combine

class BatchScheduler<T> {
    private var scheduled = PassthroughSubject<T, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init(batchSize: Int, maxDelay: RunLoop.SchedulerTimeType.Stride, _ handler: @escaping ([T]) async -> Void) {
        self.scheduled
            .collect(.byTimeOrCount(RunLoop.main, maxDelay, batchSize))
            .map { batch in
                Task.detached(priority: .background) { [batch] in
                    await handler(batch)
                }
            }
            .sink { t in
                self.cancellables.insert(AnyCancellable(t.cancel))
            }
            .store(in: &self.cancellables)
    }

    public func schedule(_ item: T) {
        self.scheduled.send(item)
    }
}
