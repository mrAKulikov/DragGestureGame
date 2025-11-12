//
//  GameViewModel.swift
//  DragGesture
//
//  Created by  Aleksei Kulikov on 07.11.2025.
//


import SwiftUI
import Combine

// MARK: - MODEL

// GameColorModel represents a color and its name
// GameColorModel представляет цвет и его имя
struct GameColorModel: Identifiable, Hashable {
    let id = UUID() // Unique identifier for SwiftUI / Уникальный идентификатор для SwiftUI
    let name: String // Color name / Название цвета
    let color: Color // SwiftUI Color / Цвет SwiftUI
}

extension GameColorModel {
    // All available colors
    // Все доступные цвета
    static let all: [GameColorModel] = [
        GameColorModel(name: "red", color: Color(red: 0.95, green: 0.35, blue: 0.35)),
        GameColorModel(name: "yellow", color: Color(red: 1.0, green: 0.85, blue: 0.3)),
        GameColorModel(name: "green", color: Color(red: 0.3, green: 0.8, blue: 0.5))
    ]
    
    // Returns a random color name
    // Возвращает случайное имя цвета
    static func randomName() -> String {
        all.randomElement()!.name
    }
}

// MARK: - VIEW MODEL

// GameViewModel contains all game logic and state
// GameViewModel содержит всю логику игры и состояние
@MainActor
class GameViewModel: ObservableObject {
    
    // MARK: - Published properties / Публикуемые свойства
    
    @Published var dragOffset: CGSize = .zero
    // Current drag offset while dragging / Смещение квадрата при перетаскивании
    
    @Published var draggedColor: GameColorModel? = nil
    ///The color currently being dragged / Цвет, который сейчас перетаскивают
    
    @Published var targetFrame: CGRect = .zero
    // Frame of the target square / Рамка нижнего квадрата цели
    
    @Published var highlightColor: Color? = nil
    // Color to highlight the target square / Цвет подсветки нижнего квадрата
    
    @Published var targetText: String = GameColorModel.randomName()
    // The name of the color to match / Название цвета, которое нужно угадать
    
    @Published var currentColor: Color = Color.gray.opacity(0.3)
    // Current color shown in the target square / Текущий цвет нижнего квадрата
    
    @Published var usedColors: Set<GameColorModel> = []
    // Colors already matched / Цвета, которые уже угаданы
    
    @Published var shakeOffset: CGFloat = 0
    // Offset for shake animation / Смещение для анимации тряски
    
    // MARK: - Game Methods / Методы игры
    
    // Reset the game to initial state
    // Сбрасывает игру в начальное состояние
    func resetGame() {
        dragOffset = .zero
        draggedColor = nil
        highlightColor = nil
        currentColor = Color.gray.opacity(0.3)
        targetText = GameColorModel.randomName()
        shakeOffset = 0
        usedColors.removeAll()
    }
    
    // Handles drop logic when user releases a square
    // Обрабатывает логику при отпускании квадрата
    func handleDrop(for color: GameColorModel, squareFrame: CGRect) {
        if squareFrame.intersects(targetFrame) {
            /// The square overlaps the target / Квадрат пересек рамку цели
            if color.name == targetText {
                // ✅ Correct match / Правильное совпадение
                withAnimation(.spring()) {
                    currentColor = color.color
                }
                draggedColor = nil
                usedColors.insert(color)
                highlightColor = nil
            } else {
                // ❌ Incorrect match / Неправильное совпадение
                dragOffset = .zero
                draggedColor = nil
                highlightColor = nil
                triggerShake() // Shake animation for wrong answer / Тряска для неправильного ответа
            }
        } else {
            // Missed target / Промах
            withAnimation(.spring()) {
                dragOffset = .zero
                draggedColor = nil
                highlightColor = nil
            }
        }
    }
    
    // Triggers a shake animation for wrong answers
    // Запускает анимацию тряски для неправильных ответов
    private func triggerShake() {
        let shakeAnimation = Animation.linear(duration: 0.05)
        let shakeTimes = 2
        for i in 0..<shakeTimes {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(i)) {
                withAnimation(shakeAnimation) {
                    // Move slightly / Слегка сдвигаем в одну сторону для визуальной тряски
                    self.shakeOffset = 20
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(shakeTimes)) {
            withAnimation(shakeAnimation) {
                self.shakeOffset = 0
            }
        }
    }
}

