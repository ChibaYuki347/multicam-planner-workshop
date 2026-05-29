"use client";

import type { Camera, Scene, Subject } from "@/lib/types";

interface Props {
  scene: Scene;
  selectedCameraId: string | null;
  onSelectCamera: (id: string | null) => void;
}

export function StageMap({ scene, selectedCameraId, onSelectCamera }: Props) {
  const { worldSize, stage, subjects, cameras, overheads } = scene;

  function findSubject(id: string | null): Subject | null {
    if (!id) return null;
    return subjects.find((s) => s.id === id) ?? null;
  }

  function conePoints(cam: Camera): string | null {
    const target = findSubject(cam.targetSubjectId);
    if (!target) return null;
    const dx = target.position.x - cam.position.x;
    const dy = target.position.y - cam.position.y;
    const theta = Math.atan2(dy, dx);
    const half = ((cam.fovDeg / 2) * Math.PI) / 180;
    const r = cam.range;
    const p1 = {
      x: cam.position.x + Math.cos(theta - half) * r,
      y: cam.position.y + Math.sin(theta - half) * r,
    };
    const p2 = {
      x: cam.position.x + Math.cos(theta + half) * r,
      y: cam.position.y + Math.sin(theta + half) * r,
    };
    return `${cam.position.x},${cam.position.y} ${p1.x},${p1.y} ${p2.x},${p2.y}`;
  }

  return (
    <svg
      viewBox={`0 0 ${worldSize.width} ${worldSize.depth}`}
      preserveAspectRatio="xMidYMid meet"
      className="stage-map"
      role="img"
      aria-label="マルチカメラ配置の上面図"
    >
      <rect
        x={0}
        y={0}
        width={worldSize.width}
        height={worldSize.depth}
        className="world"
        onClick={() => onSelectCamera(null)}
      />

      <rect
        x={stage.origin.x}
        y={stage.origin.y}
        width={stage.width}
        height={stage.depth}
        className="stage"
      />
      <text
        x={stage.origin.x + stage.width / 2}
        y={stage.origin.y + 0.55}
        textAnchor="middle"
        className="stage-label"
      >
        STAGE
      </text>

      {overheads.map((o) => (
        <g key={o.id} className="overhead">
          <circle
            cx={o.position.x}
            cy={o.position.y}
            r={o.coverageRadius}
            className="overhead-coverage"
          />
          <rect
            x={o.position.x - 0.25}
            y={o.position.y - 0.25}
            width={0.5}
            height={0.5}
            className="overhead-marker"
          />
          <text
            x={o.position.x}
            y={o.position.y + 0.85}
            textAnchor="middle"
            className="overhead-label"
          >
            {o.label}
          </text>
        </g>
      ))}

      {cameras.map((cam) => {
        const points = conePoints(cam);
        const selected = cam.id === selectedCameraId;
        return (
          <g
            key={cam.id}
            className={selected ? "camera selected" : "camera"}
            onClick={() => onSelectCamera(cam.id)}
          >
            {points && <polygon points={points} className="fov-cone" />}
            <circle
              cx={cam.position.x}
              cy={cam.position.y}
              r={0.3}
              className="camera-marker"
            />
            <text
              x={cam.position.x}
              y={cam.position.y - 0.55}
              textAnchor="middle"
              className="camera-label"
            >
              {cam.label}
            </text>
          </g>
        );
      })}

      {subjects.map((s) => (
        <g key={s.id} className="subject">
          <circle
            cx={s.position.x}
            cy={s.position.y}
            r={0.4}
            className="subject-marker"
          />
          <text
            x={s.position.x}
            y={s.position.y + 0.05}
            textAnchor="middle"
            dominantBaseline="middle"
            className="subject-id"
          >
            {s.label.slice(-1)}
          </text>
        </g>
      ))}
    </svg>
  );
}
