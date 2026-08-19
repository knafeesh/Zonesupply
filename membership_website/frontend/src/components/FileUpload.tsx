import { useRef, useState } from 'react';

interface FileUploadProps {
  label: string;
  id: string;
  accept?: string;
  required?: boolean;
  value: File | null;
  onChange: (file: File | null) => void;
  hint?: string;
}

const FileUpload = ({ label, id, accept = '.jpg,.jpeg,.png,.pdf', required, value, onChange, hint }: FileUploadProps) => {
  const inputRef = useRef<HTMLInputElement>(null);
  const [dragOver, setDragOver] = useState(false);

  const handleFile = (file: File | null) => {
    if (!file) { onChange(null); return; }
    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      alert('File size must be under 5MB');
      return;
    }
    onChange(file);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    const file = e.dataTransfer.files[0] || null;
    handleFile(file);
  };

  const getFileIcon = (type: string) => {
    if (type.includes('pdf')) return '📄';
    if (type.includes('image')) return '🖼️';
    return '📎';
  };

  const formatSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  return (
    <div>
      <label htmlFor={id} className="label">
        {label}
        {required && <span className="text-red-500 ml-1">*</span>}
      </label>

      {value ? (
        /* File Selected State */
        <div className="flex items-center gap-3 p-4 rounded-xl border-2 border-brand-300 bg-brand-50">
          <div className="text-2xl">{getFileIcon(value.type)}</div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-gray-800 truncate">{value.name}</p>
            <p className="text-xs text-gray-500">{formatSize(value.size)}</p>
          </div>
          <button
            type="button"
            onClick={() => { onChange(null); if (inputRef.current) inputRef.current.value = ''; }}
            className="flex-shrink-0 w-8 h-8 rounded-full bg-red-100 hover:bg-red-200 
                       text-red-600 flex items-center justify-center transition-colors duration-150 text-sm"
            title="Remove file"
          >
            ✕
          </button>
        </div>
      ) : (
        /* Drop Zone */
        <div
          className={`relative rounded-xl border-2 border-dashed cursor-pointer
            transition-all duration-200
            ${dragOver
              ? 'border-brand-500 bg-brand-50'
              : 'border-gray-200 bg-gray-50 hover:border-brand-300 hover:bg-brand-50/50'
            }`}
          onClick={() => inputRef.current?.click()}
          onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
          onDragLeave={() => setDragOver(false)}
          onDrop={handleDrop}
        >
          <div className="flex flex-col items-center justify-center py-6 px-4 text-center">
            <div className={`w-12 h-12 rounded-xl mb-3 flex items-center justify-center transition-colors duration-200
              ${dragOver ? 'bg-brand-100' : 'bg-white border border-gray-200'}`}>
              <svg className="w-6 h-6 text-brand-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
                  d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
              </svg>
            </div>
            <p className="text-sm font-semibold text-gray-700">
              {dragOver ? 'Drop it here!' : 'Click to upload or drag & drop'}
            </p>
            <p className="text-xs text-gray-400 mt-1">
              {hint || 'JPG, PNG or PDF — max 5MB'}
            </p>
          </div>
          <input
            ref={inputRef}
            id={id}
            type="file"
            accept={accept}
            className="hidden"
            onChange={(e) => handleFile(e.target.files?.[0] || null)}
          />
        </div>
      )}
    </div>
  );
};

export default FileUpload;
