import { useState, useMemo, useRef, useEffect } from 'react';
import { Search, X, ChevronDown } from 'lucide-react';
import clsx from 'clsx';

interface Option {
    id: string;
    label: string;
    subLabel?: string;
}

interface SearchableSelectProps {
    options: Option[];
    value: string | null;
    onChange: (value: string | null) => void;
    placeholder: string;
    icon?: React.ReactNode;
    activeColor?: string;
}

export function SearchableSelect({ options, value, onChange, placeholder, icon, activeColor = "border-blue-500" }: SearchableSelectProps) {
    const [isOpen, setIsOpen] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const wrapperRef = useRef<HTMLDivElement>(null);

    // Close when clicking outside
    useEffect(() => {
        function handleClickOutside(event: MouseEvent) {
            if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
                setIsOpen(false);
            }
        }
        document.addEventListener("mousedown", handleClickOutside);
        return () => document.removeEventListener("mousedown", handleClickOutside);
    }, [wrapperRef]);

    // Filter options
    const filteredOptions = useMemo(() => {
        if (!searchTerm) return options;
        const lower = searchTerm.toLowerCase();
        return options.filter(opt =>
            opt.label.toLowerCase().includes(lower) ||
            opt.subLabel?.toLowerCase().includes(lower)
        );
    }, [options, searchTerm]);

    // Selected Option Label
    const selectedLabel = useMemo(() => {
        return options.find(o => o.id === value)?.label || '';
    }, [options, value]);

    const handleSelect = (id: string | null) => {
        onChange(id);
        setIsOpen(false);
        setSearchTerm('');
    };

    return (
        <div className="relative" ref={wrapperRef}>
            {/* Trigger Area */}
            <div
                className={clsx(
                    "flex items-center gap-3 p-3 rounded-lg border bg-gray-900 cursor-pointer transition-all",
                    isOpen ? activeColor : "border-gray-800 hover:border-gray-700"
                )}
                onClick={() => setIsOpen(!isOpen)}
            >
                <div className={clsx("transition-colors", value ? "text-white" : "text-gray-500")}>
                    {icon || <Search size={18} />}
                </div>

                <div className="flex-1 min-w-0">
                    {value ? (
                        <span className="block truncate font-medium text-white">{selectedLabel}</span>
                    ) : (
                        <span className="block truncate text-gray-500">{placeholder}</span>
                    )}
                </div>

                <div className="text-gray-500">
                    {value ? (
                        <div
                            className="p-1 hover:bg-gray-800 rounded-full"
                            onClick={(e) => {
                                e.stopPropagation();
                                handleSelect(null);
                            }}
                        >
                            <X size={14} />
                        </div>
                    ) : (
                        <ChevronDown size={14} />
                    )}
                </div>
            </div>

            {/* Dropdown */}
            {isOpen && (
                <div className="absolute top-full left-0 right-0 mt-2 bg-gray-900 border border-gray-800 rounded-lg shadow-2xl z-50 overflow-hidden animate-in fade-in zoom-in-95 duration-100">
                    {/* Search Input */}
                    <div className="p-2 border-b border-gray-800">
                        <div className="flex items-center bg-gray-950 rounded px-2 border border-gray-800 focus-within:border-gray-600">
                            <Search size={14} className="text-gray-500 mr-2" />
                            <input
                                type="text"
                                className="w-full bg-transparent border-none py-2 text-sm text-white focus:outline-none placeholder-gray-600"
                                placeholder="Search station..."
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                                autoFocus
                                onClick={(e) => e.stopPropagation()}
                            />
                        </div>
                    </div>

                    {/* List */}
                    <div className="max-h-60 overflow-y-auto custom-scrollbar">
                        {filteredOptions.length > 0 ? (
                            filteredOptions.map(opt => (
                                <div
                                    key={opt.id}
                                    className={clsx(
                                        "px-4 py-2 cursor-pointer hover:bg-gray-800 transition-colors flex flex-col",
                                        value === opt.id ? "bg-gray-800/50" : ""
                                    )}
                                    onClick={() => handleSelect(opt.id)}
                                >
                                    <span className="text-sm font-medium text-gray-200">{opt.label}</span>
                                    {opt.subLabel && <span className="text-xs text-gray-500">{opt.subLabel}</span>}
                                </div>
                            ))
                        ) : (
                            <div className="p-4 text-center text-gray-500 text-sm">
                                No stations found
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
}
