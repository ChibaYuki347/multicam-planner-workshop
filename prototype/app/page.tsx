"use client";

import { useState } from "react";
import { defaultScene } from "@/lib/mock";
import { CameraPanel } from "./components/CameraPanel";
import { IntentCard } from "./components/IntentCard";
import { StageMap } from "./components/StageMap";

export default function HomePage() {
  const [scene] = useState(defaultScene);
  const [selectedCameraId, setSelectedCameraId] = useState<string | null>(null);

  const selectedCamera =
    scene.cameras.find((c) => c.id === selectedCameraId) ?? null;

  return (
    <main className="layout">
      <header>
        <h1>Multi-Camera Capture Planner</h1>
        <p>Spec-Driven Development Workshop · プロトタイプ雛形</p>
      </header>

      <section className="map-area" aria-label="Stage top-down view">
        <StageMap
          scene={scene}
          selectedCameraId={selectedCameraId}
          onSelectCamera={setSelectedCameraId}
        />
      </section>

      <aside className="side">
        <section>
          <h2>カメラ一覧</h2>
          <CameraPanel
            scene={scene}
            selectedCameraId={selectedCameraId}
            onSelectCamera={setSelectedCameraId}
          />
        </section>
        <section>
          <div className="side-heading">
            <h2>撮影意図</h2>
            {selectedCameraId && (
              <button
                type="button"
                className="link-button"
                onClick={() => setSelectedCameraId(null)}
              >
                選択解除
              </button>
            )}
          </div>
          <IntentCard scene={scene} camera={selectedCamera} />
        </section>
      </aside>

      <footer>
        <p>
          これはワークショップ用の雛形です。仕様 → 計画 → 実装の各サイクルで
          GitHub Copilot に変更を依頼し、機能を拡張してください。
        </p>
      </footer>
    </main>
  );
}
