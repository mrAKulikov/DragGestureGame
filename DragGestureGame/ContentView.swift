//
//  ContentView.swift
//  DragGesture
//
//  Created by  Aleksei Kulikov on 07.11.2025.
//

import SwiftUI

// MARK: - MAIN CONTENT VIEW

// ContentView is the main view combining all components
// ContentView это главный View, объединяющий все элементы игры

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    
    // ViewModel handles all game logic and state
    // ViewModel управляет всей логикой и состоянием игры
    
    var body: some View {
        GeometryReader { geometry in
            
            // GeometryReader gives the available size of the screen
            // GeometryReader позволяет узнать доступный размер экрана
            
            ZStack {
                
                // ZStack allows stacking views on top of each other
                // ZStack позволяет накладывать View друг на друга
                
                VStack {
                    // Title / Заголовок
                    Text("Match colors to words")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    // Top draggable squares / Верхние перетаскиваемые квадраты
                    HStack(spacing: geometry.size.width * 0.05) {
                        // HStack arranges squares horizontally / HStack располагает квадраты горизонтально
                        ForEach(GameColorModel.all) { color in
                            // ForEach loops over all colors / ForEach перебирает все цвета
                            DraggableSquareView(
                                color: color,
                                squareSize: min(100, geometry.size.width / 4),
                                viewModel: viewModel
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                    // Spacer pushes content apart / Spacer разделяет элементы
                    
                    // Bottom target square / Нижний квадрат цели
                    TargetSquareView(
                        viewModel: viewModel,
                        squareSize: min(160, geometry.size.width * 0.4)
                    )
                    
                    Spacer()
                    
                    // Restart button / Кнопка перезапуска
                    Button(action: viewModel.resetGame) {
                        Text("Restart")
                            .font(.headline)
                            .bold()
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
                .offset(x: viewModel.shakeOffset)
                // Shake animation when wrong answer / Анимация тряски при неправильном ответе
            }
        }
        .padding()
    }
}

// MARK: - DRAGGABLE SQUARE VIEW

// DraggableSquareView represents a draggable color square
// DraggableSquareView представляет перетаскиваемый цветной квадрат

struct DraggableSquareView: View {
    let color: GameColorModel
    let squareSize: CGFloat
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.usedColors.contains(color) ? color.color.opacity(0) : color.color)
                .frame(width: squareSize, height: squareSize)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                // Move the square while dragging / Сдвигаем квадрат при перетаскивании
                .offset(viewModel.draggedColor == color ? viewModel.dragOffset : .zero)
                .gesture(
                    DragGesture() // Create a drag gesture / Создаем жест перетаскивания
                        .onChanged { value in
                            // Called every time the finger moves / Вызывается каждый раз, когда палец двигается
                            // value.translation contains the finger offset / value.translation содержит смещение пальца
                            
                            // Set the currently dragged color / Устанавливаем текущий перетаскиваемый цвет
                            viewModel.draggedColor = color
                            
                            // Save the drag offset to move the square / Сохраняем смещение для движения квадрата
                            viewModel.dragOffset = value.translation
                            
                            // Calculate the square center including the offset / Вычисляем центр квадрата с учётом смещения
                            let squareCenter = CGPoint(
                                x: geo.frame(in: .global).midX + viewModel.dragOffset.width,
                                y: geo.frame(in: .global).midY + viewModel.dragOffset.height
                            )
                            
                            // Highlight the target if the square overlaps / Подсвечиваем цель, если квадрат пересекает её
                            viewModel.highlightColor = viewModel.targetFrame.contains(squareCenter) ? color.color : nil
                        }
                        .onEnded { _ in
                            // Called when the finger is lifted / Вызывается, когда палец отпущен
                            
                            // Compute the final frame of the square / Вычисляем финальную рамку квадрата
                            let squareFrame = geo.frame(in: .global)
                                .offsetBy(dx: viewModel.dragOffset.width, dy: viewModel.dragOffset.height)
                            
                            // Handle drop logic in the ViewModel / Передаем логику отпускания в ViewModel
                            viewModel.handleDrop(for: color, squareFrame: squareFrame)
                        }
                )
        }
        .frame(width: squareSize, height: squareSize)
    }
}

// MARK: - TARGET SQUARE VIEW

// TargetSquareView represents the bottom square with the target color name
// TargetSquareView представляет нижний квадрат с текстом цели
struct TargetSquareView: View {
    @ObservedObject var viewModel: GameViewModel
    let squareSize: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentColor)
                .frame(width: squareSize, height: squareSize)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(viewModel.highlightColor ?? Color.clear, lineWidth: 8)
                )
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { viewModel.targetFrame = geo.frame(in: .global) }
                            .onChange(of: geo.frame(in: .global)) { newValue in
                                viewModel.targetFrame = newValue
                            }
                            // Updates the target frame when layout changes / Обновляет рамку цели при изменении layout
                    }
                )
            
            Text(viewModel.targetText)
                .font(.title)
                .bold()
                .foregroundColor(.black)
                .frame(width: squareSize, height: squareSize)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - PREVIEW

#Preview {
    ContentView()
}
