"use client";

import type { Scene } from "@/lib/types";

interface Props {
  scene: Scene;
  selectedCameraId: string | null;
  onSelectCamera: (id: string) => void;
}

export function CameraPanel({ scene, selectedCameraId, onSelectCamera }: Props) {
  return (
    <ul className="camera-list">
      {scene.cameras.map((cam) => {
        const subject = scene.subjects.find((s) => s.id === cam.targetSubjectId);
        const selected = cam.id === selectedCameraId;
        return (
          <li key={cam.id}>
            <button
              type="button"
              className={selected ? "camera-item selected" : "camera-item"}
              onClick={() => onSelectCamera(cam.id)}
              aria-pressed={selected}
            >
              <span className="camera-item-label">{cam.label}</span>
              <span className="camera-item-target">
                → {subject ? subject.label : "未割り当て"}
              </span>
              <span className="camera-item-intent">{cam.intent}</span>
            </button>
          </li>
        );
      })}
    </ul>
  );
}
