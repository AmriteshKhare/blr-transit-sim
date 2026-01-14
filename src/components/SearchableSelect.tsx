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
                    "flex items-center gap-3 p-3 rounded-sm border cursor-pointer transition-all group",
                    isOpen ? activeColor + " bg-white shadow-md ring-1 ring-stone-900/5 scale-[1.01]" : "border-stone-200 hover:border-orange-200 hover:bg-white bg-stone-50"
                )}
                onClick={() => setIsOpen(!isOpen)}
            >
                <div className={clsx("transition-colors", value ? "text-stone-900" : "text-stone-400 group-hover:text-stone-600")}>
                    {icon || <Search size={16} />}
                </div>

                <div className="flex-1 min-w-0">
                    {value ? (
                        <span className="block truncate text-xs font-bold tracking-wide text-stone-900">{selectedLabel}</span>
                    ) : (
                        <span className="block truncate text-xs tracking-wide text-stone-400 group-hover:text-stone-500 transition-colors uppercase font-bold">{placeholder}</span>
                    )}
                </div>

                <div className="text-stone-400 group-hover:text-stone-600 transition-colors">
                    {value ? (
                        <div
                            className="p-1 hover:bg-stone-200 rounded-full"
                            onClick={(e) => {
                                e.stopPropagation();
                                handleSelect(null);
                            }}
                        >
                            <X size={12} />
                        </div>
                    ) : (
                        <ChevronDown size={12} />
                    )}
                </div>
            </div>

            {/* Dropdown */}
            {isOpen && (
                <div className="absolute top-full left-0 right-0 mt-1 bg-white border border-stone-200 rounded-sm shadow-xl z-50 overflow-hidden animate-in fade-in zoom-in-95 duration-100 ring-1 ring-black/5">
                    {/* Search Input */}
                    <div className="p-2 border-b border-stone-100">
                        <div className="flex items-center bg-stone-50 rounded-sm px-2 border border-stone-200 focus-within:border-stone-300">
                            <Search size={12} className="text-stone-400 mr-2" />
                            <input
                                type="text"
                                className="w-full bg-transparent border-none py-2 text-xs text-stone-900 focus:outline-none placeholder-stone-400 tracking-wide uppercase font-bold"
                                placeholder="TYPE TO SEARCH..."
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
                                        "px-4 py-2 cursor-pointer hover:bg-stone-50 transition-colors flex flex-col group border-b border-stone-100 last:border-0",
                                        value === opt.id ? "bg-orange-50/50" : ""
                                    )}
                                    onClick={() => handleSelect(opt.id)}
                                >
                                    <span className={clsx("text-xs font-bold tracking-wide", value === opt.id ? "text-stone-900" : "text-stone-500 group-hover:text-stone-800 transition-colors")}>{opt.label}</span>
                                    {opt.subLabel && <span className="text-[10px] text-stone-400 group-hover:text-stone-500 uppercase tracking-widest mt-0.5 font-bold">{opt.subLabel}</span>}
                                </div>
                            ))
                        ) : (
                            <div className="p-4 text-center text-stone-400 text-xs tracking-wide uppercase font-medium">
                                No matching stations
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
}
