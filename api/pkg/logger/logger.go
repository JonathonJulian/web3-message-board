package logger

import (
	"context"
	"io"
	"log/slog"
	"os"
	"time"
)

// Logger is a wrapper around slog.Logger
type Logger struct {
	*slog.Logger
}

// Config holds logger configuration
type Config struct {
	Level      string // debug, info, warn, error
	JSONOutput bool   // true for JSON, false for text
	Output     io.Writer
}

// DefaultConfig returns the default logger configuration
func DefaultConfig() Config {
	return Config{
		Level:      "info",
		JSONOutput: false,
		Output:     os.Stdout,
	}
}

// New creates a new logger with the given configuration
func New(cfg Config) *Logger {
	var level slog.Level
	switch cfg.Level {
	case "debug":
		level = slog.LevelDebug
	case "info":
		level = slog.LevelInfo
	case "warn":
		level = slog.LevelWarn
	case "error":
		level = slog.LevelError
	default:
		level = slog.LevelInfo
	}

	var handler slog.Handler
	opts := &slog.HandlerOptions{
		Level: level,
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			if a.Key == slog.TimeKey {
				a.Value = slog.StringValue(a.Value.Time().Format(time.RFC3339))
			}
			return a
		},
	}

	if cfg.JSONOutput {
		handler = slog.NewJSONHandler(cfg.Output, opts)
	} else {
		handler = slog.NewTextHandler(cfg.Output, opts)
	}

	slogger := slog.New(handler)
	return &Logger{slogger}
}

// WithContext returns a new logger with request-specific context information
func (l *Logger) WithContext(ctx context.Context) *Logger {
	// Example: Add trace IDs or request IDs from context if they exist
	// For now, we're just returning the existing logger
	return l
}

// WithField adds a field to the logger
func (l *Logger) WithField(key string, value interface{}) *Logger {
	return &Logger{l.With(key, value)}
}

// WithFields adds multiple fields to the logger
func (l *Logger) WithFields(fields map[string]interface{}) *Logger {
	logger := l.Logger
	for k, v := range fields {
		logger = logger.With(k, v)
	}
	return &Logger{logger}
}
