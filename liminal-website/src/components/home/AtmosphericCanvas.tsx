"use client";

import { createContext, useContext, useEffect, useState } from "react";
import { Canvas } from "@react-three/fiber";

export interface SceneContextValue {
  progress: number;
  isMobile: boolean;
}

const SceneContext = createContext<SceneContextValue>({
  progress: 0,
  isMobile: false,
});

export function useScene() {
  return useContext(SceneContext);
}

interface AtmosphericCanvasProps {
  children: React.ReactNode;
  progress?: number;
  className?: string;
}

export default function AtmosphericCanvas({
  children,
  progress = 0,
  className = "",
}: AtmosphericCanvasProps) {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 768);
    check();
    window.addEventListener("resize", check);
    return () => window.removeEventListener("resize", check);
  }, []);

  const dpr = isMobile ? ([0.5, 1] as [number, number]) : ([1, 1.5] as [number, number]);

  return (
    <div className={`absolute inset-0 ${className}`}>
      <Canvas
        gl={{ antialias: !isMobile, alpha: true, powerPreference: "low-power" }}
        dpr={dpr}
        style={{ background: "transparent" }}
        camera={{ position: [0, 0.5, 4], fov: 40 }}
      >
        <SceneContext.Provider value={{ progress, isMobile }}>
          {children}
        </SceneContext.Provider>
      </Canvas>
    </div>
  );
}
