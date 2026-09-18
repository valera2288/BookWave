import { Component, type ErrorInfo, type ReactNode } from "react";

interface Props {
  children: ReactNode;
}

interface State {
  error: Error | null;
}

/** Без этого необработанная ошибка рендера где-то в разделе (например,
 * неожиданная форма данных с сервера) размонтирует всё дерево React и
 * оставляет полностью пустой экран без единой подсказки, что случилось. */
export default class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error("Необработанная ошибка при отображении страницы:", error, info.componentStack);
  }

  render() {
    if (this.state.error) {
      return (
        <div style={{ padding: 32 }}>
          <p className="error-banner">
            Произошла ошибка при отображении страницы: {this.state.error.message}
          </p>
          <button type="button" onClick={() => this.setState({ error: null })}>
            Попробовать снова
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}
